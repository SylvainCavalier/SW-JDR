class SpaceCombatController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!
  before_action :set_current_user

  def index
    @combat = SpaceCombatState.active_combat.first_or_create!(turn: 1, active: true)
    @participants = @combat.space_combat_participants
                           .includes(:participant)
                           .order(Arel.sql("action_order ASC NULLS LAST, initiative_roll DESC NULLS LAST"))
    @positions = @combat.ship_combat_positions.includes(:participant_a, :participant_b)
    @actions = @combat.space_combat_actions.order(created_at: :desc).limit(50)
    @ships = Ship.joins(:group).where(groups: { name: "PJ" }).order(:name)
  end

  def add_ship
    @combat = SpaceCombatState.active_combat.first!
    ship = Ship.find(params[:ship_id])

    # Vérifier que le vaisseau n'est pas déjà dans le combat
    if @combat.space_combat_participants.where(participant: ship).exists?
      flash[:alert] = "Ce vaisseau est déjà dans le combat."
      redirect_to space_combat_path and return
    end

    participant = @combat.space_combat_participants.create!(
      participant: ship,
      side: 0
    )

    # Créer les paires de position avec tous les ennemis
    @combat.space_combat_participants.enemies.each do |enemy_participant|
      create_position_pair(@combat, participant, enemy_participant)
    end

    log_action(participant, "ajout", "#{ship.name} rejoint le combat")
    broadcast_full_update
    flash[:notice] = "#{ship.name} ajouté au combat."
    redirect_to space_combat_path
  end

  def add_enemy_ship
    @combat = SpaceCombatState.active_combat.first!

    enemy_ship = EnemyShip.new(enemy_ship_params)
    enemy_ship.hp_current = enemy_ship.hp_max
    enemy_ship.shield_current = enemy_ship.shield_max

    if enemy_ship.save
      participant = @combat.space_combat_participants.create!(
        participant: enemy_ship,
        side: 1
      )

      # Créer les paires de position avec tous les joueurs
      @combat.space_combat_participants.players.each do |player_participant|
        create_position_pair(@combat, player_participant, participant)
      end

      log_action(participant, "ajout", "#{enemy_ship.name} apparaît")
      broadcast_full_update
      flash[:notice] = "#{enemy_ship.name} ajouté au combat."
    else
      flash[:alert] = "Erreur : #{enemy_ship.errors.full_messages.join(', ')}"
    end
    redirect_to space_combat_path
  end

  def remove_participant
    @combat = SpaceCombatState.active_combat.first!
    participant = @combat.space_combat_participants.find(params[:id])

    ship_name = participant.ship_name

    # Supprimer les positions associées
    ShipCombatPosition.where(
      "participant_a_id = ? OR participant_b_id = ?", participant.id, participant.id
    ).destroy_all

    # Détruire l'EnemyShip si c'est un ennemi (comme Enemy pour le combat au sol)
    participant.participant.destroy if participant.participant.is_a?(EnemyShip)
    participant.destroy

    broadcast_full_update
    flash[:notice] = "#{ship_name} retiré du combat."
    redirect_to space_combat_path
  end

  def roll_initiative
    @combat = SpaceCombatState.active_combat.first!
    results = []

    @combat.space_combat_participants.each do |participant|
      ship = participant.participant
      mastery, bonus = speed_stats_for(ship)
      roll = SpaceCombatRules.roll_dice(mastery)
      total = roll[:total] + bonus
      participant.update!(initiative_roll: total)
      results << { name: ship.name, rolls: roll[:individual], bonus: bonus, total: total }
    end

    # Attribuer l'ordre d'action par initiative décroissante
    @combat.space_combat_participants
           .order(initiative_roll: :desc)
           .each_with_index do |p, i|
      p.update!(action_order: i + 1)
    end

    # Loguer les résultats
    results.sort_by { |r| -r[:total] }.each do |r|
      first_participant = @combat.space_combat_participants
                                 .joins("INNER JOIN ships ON space_combat_participants.participant_type = 'Ship' AND space_combat_participants.participant_id = ships.id")
                                 .where(ships: { name: r[:name] })
                                 .first
      first_participant ||= @combat.space_combat_participants
                                   .joins("INNER JOIN enemy_ships ON space_combat_participants.participant_type = 'EnemyShip' AND space_combat_participants.participant_id = enemy_ships.id")
                                   .where(enemy_ships: { name: r[:name] })
                                   .first

      if first_participant
        log_action(first_participant, "initiative",
                   "#{r[:name]} : [#{r[:rolls].join(', ')}] + #{r[:bonus]} = #{r[:total]}")
      end
    end

    broadcast_full_update
    render json: { success: true, results: results }
  end

  def change_position
    @combat = SpaceCombatState.active_combat.first!
    mover = @combat.space_combat_participants.find(params[:mover_id])
    target = @combat.space_combat_participants.find(params[:target_id])
    desired_position = params[:desired_position]

    mover_ship = mover.participant
    target_ship = target.participant

    # Jet opposé Pilotage
    atk_m, atk_b = piloting_stats_for(mover_ship)
    def_m, def_b = piloting_stats_for(target_ship)

    result = SpaceCombatRules.opposed_roll(atk_m, atk_b, def_m, def_b)
    position_record = ShipCombatPosition.find_pair(@combat.id, mover.id, target.id)

    if result[:winner] == :attacker && position_record
      # Déterminer la position dans la table
      new_position = resolve_position(mover, target, desired_position, position_record)
      position_record.update!(position: new_position)

      log_action(mover, "mouvement",
                 "#{mover.ship_name} manoeuvre vs #{target.ship_name} : " \
                 "[#{result[:attacker][:rolls].join(', ')}]+#{result[:attacker][:bonus]}=#{result[:attacker][:total]} " \
                 "vs [#{result[:defender][:rolls].join(', ')}]+#{result[:defender][:bonus]}=#{result[:defender][:total]} " \
                 "=> #{position_record.position_label_for(mover)}")
    else
      log_action(mover, "mouvement",
                 "#{mover.ship_name} échoue sa manoeuvre vs #{target.ship_name} : " \
                 "[#{result[:attacker][:rolls].join(', ')}]+#{result[:attacker][:bonus]}=#{result[:attacker][:total]} " \
                 "vs [#{result[:defender][:rolls].join(', ')}]+#{result[:defender][:bonus]}=#{result[:defender][:total]}")
    end

    mover.update!(movement_action_used: true)
    broadcast_full_update
    render json: { success: true, result: result }
  end

  def update_stat
    @combat = SpaceCombatState.active_combat.first!
    participant = @combat.space_combat_participants.find(params[:participant_id])
    ship = participant.participant

    unless can_modify_ship?(participant)
      render json: { success: false, error: "Permissions insuffisantes" }, status: :unauthorized
      return
    end

    field = params[:field]
    unless %w[hp_current shield_current].include?(field)
      render json: { success: false, error: "Champ invalide" }, status: :bad_request
      return
    end

    old_value = ship.send(field)
    new_value = params[:value].to_i

    if ship.update(field => new_value)
      action_type = case field
                    when "hp_current"
                      new_value > old_value ? "bouclier" : "degats"
                    when "shield_current"
                      "bouclier"
                    end

      log_action(participant, action_type,
                 "#{ship.name} : #{field == 'hp_current' ? 'PV' : 'Bouclier'} #{old_value} -> #{new_value}")

      broadcast_full_update
      render json: { success: true }
    else
      render json: { success: false, errors: ship.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_damage_flag
    @combat = SpaceCombatState.active_combat.first!
    participant = @combat.space_combat_participants.find(params[:participant_id])
    ship = participant.participant

    flag = params[:flag]
    valid_flags = %w[shields_disabled controls_ionized weapon_damaged
                     thrusters_damaged hyperdrive_broken depressurized ship_destroyed]

    unless valid_flags.include?(flag)
      render json: { success: false, error: "Flag invalide" }, status: :bad_request
      return
    end

    new_value = !ship.send(flag)
    ship.update!(flag => new_value)

    log_action(participant, "flag_damage",
               "#{ship.name} : #{flag.humanize} #{new_value ? 'activé' : 'désactivé'}")

    broadcast_full_update
    render json: { success: true }
  end

  def fire_weapon
    @combat = SpaceCombatState.active_combat.first!
    attacker = @combat.space_combat_participants.find(params[:attacker_id])
    target = @combat.space_combat_participants.find(params[:target_id])
    weapon_name = params[:weapon_name]
    weapon_type = params[:weapon_type]

    position_record = ShipCombatPosition.find_pair(@combat.id, attacker.id, target.id)
    unless position_record
      render json: { success: false, error: "Pas de position entre ces vaisseaux" }, status: :bad_request
      return
    end

    relative_pos = position_record.relative_position_for(attacker)
    unless SpaceCombatRules.can_fire?(relative_pos, weapon_type)
      render json: { success: false, error: "Tir impossible depuis cette position" }, status: :bad_request
      return
    end

    bonus_dice = SpaceCombatRules.aim_bonus_dice(relative_pos)

    log_action(attacker, "tir",
               "#{attacker.ship_name} tire avec #{weapon_name} sur #{target.ship_name}" \
               "#{bonus_dice.positive? ? " (+#{bonus_dice}D bonus poursuivant)" : ''}",
               target)

    attacker.update!(offensive_action_used: true)
    broadcast_full_update
    render json: { success: true, bonus_dice: bonus_dice }
  end

  def defend
    @combat = SpaceCombatState.active_combat.first!
    participant = @combat.space_combat_participants.find(params[:participant_id])
    participant.update!(defense_malus: participant.defense_malus + 1)

    log_action(participant, "esquive",
               "#{participant.ship_name} effectue une manoeuvre d'esquive (malus défense : #{participant.defense_malus})")

    broadcast_full_update
    render json: { success: true }
  end

  def end_turn
    @combat = SpaceCombatState.active_combat.first!
    participant = @combat.space_combat_participants.find(params[:participant_id])
    participant.update!(has_played: true)

    log_action(participant, "fin_tour", "#{participant.ship_name} termine son tour")

    broadcast_full_update
    render json: { success: true }
  end

  def next_turn
    @combat = SpaceCombatState.active_combat.first!
    @combat.space_combat_participants.each(&:reset_turn!)
    @combat.update!(turn: @combat.turn + 1)

    broadcast_full_update
    render json: { success: true }
  end

  def end_combat
    @combat = SpaceCombatState.active_combat.first!

    # Nettoyer les EnemyShips
    @combat.space_combat_participants.enemies.each do |p|
      p.participant.destroy if p.participant.is_a?(EnemyShip)
    end

    @combat.space_combat_participants.destroy_all
    @combat.ship_combat_positions.destroy_all
    @combat.update!(active: false)

    flash[:notice] = "Combat spatial terminé."
    redirect_to space_combat_path
  end

  def override_position
    @combat = SpaceCombatState.active_combat.first!
    position_record = @combat.ship_combat_positions.find(params[:position_id])
    new_position = params[:new_position]

    position_record.update!(position: new_position)

    a_name = position_record.participant_a.ship_name
    b_name = position_record.participant_b.ship_name
    log_action(position_record.participant_a, "position_override",
               "Position forcée : #{a_name} / #{b_name} -> #{position_record.position_label}")

    broadcast_full_update
    render json: { success: true }
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def enemy_ship_params
    params.require(:enemy_ship).permit(
      :name, :hp_max, :shield_max, :speed_mastery, :speed_bonus,
      :piloting_mastery, :piloting_bonus, :scale,
      enemy_ship_weapons_attributes: [
        :id, :name, :weapon_type, :damage_mastery, :damage_bonus,
        :aim_mastery, :aim_bonus, :quantity_current, :quantity_max, :_destroy
      ]
    )
  end

  def can_modify_ship?(participant)
    return true if current_user.group.name == "MJ"
    return false unless participant.side.zero?

    ship = participant.participant
    ship.is_a?(Ship) && ship.group_id == current_user.group_id
  end

  def speed_stats_for(ship)
    if ship.is_a?(Ship)
      skill = ship.ships_skills.joins(:skill).find_by(skills: { name: "Vitesse" })
      skill ? [skill.mastery, skill.bonus] : [1, 0]
    else
      [ship.speed_mastery, ship.speed_bonus]
    end
  end

  def piloting_stats_for(ship)
    if ship.is_a?(Ship)
      skill = ship.ships_skills.joins(:skill).find_by(skills: { name: "Maniabilité" })
      skill ? [skill.mastery, skill.bonus] : [1, 0]
    else
      [ship.piloting_mastery, ship.piloting_bonus]
    end
  end

  def create_position_pair(combat, participant_player, participant_enemy)
    a_id, b_id = [participant_player.id, participant_enemy.id].sort
    ShipCombatPosition.find_or_create_by!(
      space_combat_state_id: combat.id,
      participant_a_id: a_id,
      participant_b_id: b_id
    )
  end

  def resolve_position(mover, target, desired, position_record)
    # Convertir la position désirée relative en position absolue dans la table
    case desired
    when "poursuivant"
      mover.id == position_record.participant_a_id ? :a_pursues_b : :b_pursues_a
    when "face_a_face"
      :face_to_face
    when "vol_parallele"
      :parallel
    when "hors_de_portee"
      :out_of_range
    else
      :out_of_range
    end
  end

  def log_action(actor_participant, action_type, value, target_participant = nil)
    SpaceCombatAction.create!(
      space_combat_state_id: actor_participant.space_combat_state_id,
      actor_participant: actor_participant,
      actor_crew_user: current_user,
      target_participant: target_participant,
      action_type: action_type,
      value: value
    )
  end

  def broadcast_full_update
    @combat.reload
    participants = @combat.space_combat_participants
                          .includes(:participant)
                          .order(Arel.sql("action_order ASC NULLS LAST, initiative_roll DESC NULLS LAST"))
    positions = @combat.ship_combat_positions.includes(:participant_a, :participant_b)

    Turbo::StreamsChannel.broadcast_replace_to(
      "space_combat_updates",
      target: "space_combat_main",
      partial: "space_combat/combat_board",
      locals: {
        combat: @combat,
        participants: participants,
        positions: positions,
        current_user: current_user
      }
    )
  end
end
