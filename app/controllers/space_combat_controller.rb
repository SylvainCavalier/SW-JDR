class SpaceCombatController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_current_user
  before_action :set_combat, except: %i[index]
  before_action :require_mj!, only: %i[add_ship add_enemy_ship remove_participant roll_initiative
                                       next_turn end_combat override_position toggle_stealth]

  DETECTION_DIFFICULTY = 15

  def index
    @combat = SpaceCombatState.active_combat.first_or_create!(turn: 1, active: true)
    @participants = ordered_participants(@combat)
    @positions = @combat.ship_combat_positions.includes(:participant_a, :participant_b)
    @actions = @combat.space_combat_actions.order(created_at: :desc).limit(50)
    @ships = Ship.joins(:group).where(groups: { name: "PJ" }).order(:name)
  end

  # --- Composition du combat ------------------------------------------------

  def add_ship
    ship = Ship.find(params[:ship_id])

    if @combat.space_combat_participants.where(participant: ship).exists?
      flash[:alert] = "Ce vaisseau est déjà dans le combat."
      return redirect_to space_combat_path
    end

    participant = @combat.space_combat_participants.create!(participant: ship, side: 0)
    @combat.space_combat_participants.enemies.each { |enemy| create_position_pair(participant, enemy) }

    log_action(participant, "ajout", "#{ship.name} rejoint le combat")
    broadcast_full_update
    flash[:notice] = "#{ship.name} ajouté au combat."
    redirect_to space_combat_path
  end

  def add_enemy_ship
    enemy_ship = EnemyShip.new(enemy_ship_params)
    enemy_ship.hp_current = enemy_ship.hp_max

    if enemy_ship.save
      participant = @combat.space_combat_participants.create!(
        participant: enemy_ship,
        side: 1,
        stealth: ActiveModel::Type::Boolean.new.cast(params[:stealth]).present?
      )
      @combat.space_combat_participants.players.each { |player| create_position_pair(player, participant) }

      log_action(participant, "ajout", "#{enemy_ship.name} apparaît#{participant.stealth? ? ' (furtif)' : ''}")
      broadcast_full_update
      flash[:notice] = "#{enemy_ship.name} ajouté au combat."
    else
      flash[:alert] = "Erreur : #{enemy_ship.errors.full_messages.join(', ')}"
    end
    redirect_to space_combat_path
  end

  def remove_participant
    participant = @combat.space_combat_participants.find(params[:id])
    ship_name = participant.ship_name

    ActiveRecord::Base.transaction do
      participant.positions.destroy_all
      @combat.space_combat_actions.where(target_participant: participant).update_all(target_participant_id: nil)
      @combat.space_combat_actions.where(actor_participant: participant).destroy_all
      participant.participant.destroy if participant.participant.is_a?(EnemyShip)
      participant.destroy
    end

    broadcast_full_update
    flash[:notice] = "#{ship_name} retiré du combat."
    redirect_to space_combat_path
  end

  # --- Initiative -----------------------------------------------------------

  def roll_initiative
    results = @combat.space_combat_participants.includes(:participant).map do |participant|
      mastery, bonus = participant.speed_roll_dice
      roll = SpaceCombatRules.roll(mastery, bonus)
      participant.update!(initiative_roll: roll[:total])
      { participant: participant, roll: roll }
    end

    results.sort_by { |entry| -entry[:roll][:total] }.each_with_index do |entry, index|
      entry[:participant].update!(action_order: index + 1)
      log_action(entry[:participant], "initiative",
                 "##{index + 1} — #{entry[:participant].ship_name} : #{SpaceCombatRules.format_roll(entry[:roll])}")
    end

    broadcast_full_update
    render json: { success: true }
  end

  # --- Mouvement ------------------------------------------------------------

  def change_position
    mover, target, position_record = movement_context
    return unless mover

    desired = params[:desired_position].to_s
    new_position = position_record.absolute_position_for(mover, desired)

    if position_record.position == new_position.to_s
      return render json: { success: false, error: "Le vaisseau est déjà dans cette position" },
                    status: :unprocessable_entity
    end

    atk_m, atk_b = mover.piloting_dice(current_user)
    def_m, def_b = target.piloting_dice
    result = SpaceCombatRules.opposed_roll(atk_m, atk_b, def_m, def_b)
    detail = "#{SpaceCombatRules.format_roll(result[:attacker])} vs #{SpaceCombatRules.format_roll(result[:defender])}"

    if result[:winner] == :attacker
      position_record.update!(position: new_position, blind_spot_for_id: nil)
      log_action(mover, "mouvement",
                 "#{mover.ship_name} manœuvre vs #{target.ship_name} (#{detail}) -> " \
                 "#{position_record.position_label_for(mover)}", target)
    else
      log_action(mover, "mouvement", "#{mover.ship_name} échoue sa manœuvre vs #{target.ship_name} (#{detail})", target)
    end

    mover.update!(movement_action_used: true)
    broadcast_full_update
    render json: { success: true, won: result[:winner] == :attacker, summary: detail }
  end

  # Poursuivi -> hors de portée en poussant les propulseurs : jet de vitesse opposé (règle 4-3)
  def boost_thrusters
    mover, target, position_record = movement_context
    return unless mover

    unless position_record.relative_position_for(mover) == :poursuivi
      return render json: { success: false, error: "Cette manœuvre n'est possible que si le vaisseau est poursuivi" },
                    status: :unprocessable_entity
    end

    atk_m, atk_b = mover.speed_roll_dice(current_user)
    def_m, def_b = target.speed_roll_dice
    result = SpaceCombatRules.opposed_roll(atk_m, atk_b, def_m, def_b)
    detail = "#{SpaceCombatRules.format_roll(result[:attacker])} vs #{SpaceCombatRules.format_roll(result[:defender])}"

    if result[:winner] == :attacker
      position_record.update!(position: :out_of_range, blind_spot_for_id: nil)
      log_action(mover, "mouvement",
                 "#{mover.ship_name} pousse ses propulseurs et se met hors de portée de #{target.ship_name} " \
                 "(vitesse #{detail}) — reste à portée de missiles", target)
    else
      log_action(mover, "mouvement",
                 "#{mover.ship_name} ne parvient pas à distancer #{target.ship_name} (vitesse #{detail})", target)
    end

    mover.update!(movement_action_used: true)
    broadcast_full_update
    render json: { success: true, won: result[:winner] == :attacker, summary: detail }
  end

  # Angle mort d'un gros vaisseau (règle 4-9)
  def attempt_blind_spot
    mover, target, position_record = movement_context
    return unless mover

    unless mover.small_ship? && target.big_ship?
      return render json: { success: false,
                            error: "Seul un petit vaisseau peut se glisser dans l'angle mort d'un gros vaisseau" },
                    status: :unprocessable_entity
    end

    unless position_record.engaged?
      return render json: { success: false, error: "Il faut avoir été attaqué au moins une fois par ce vaisseau" },
                    status: :unprocessable_entity
    end

    atk_m, atk_b = mover.piloting_dice(current_user)
    def_m, def_b = target.piloting_dice
    result = SpaceCombatRules.opposed_roll(atk_m, atk_b, def_m, def_b)
    detail = "#{SpaceCombatRules.format_roll(result[:attacker])} vs #{SpaceCombatRules.format_roll(result[:defender])}"

    if result[:winner] == :attacker
      position_record.update!(blind_spot_for_id: mover.id)
      log_action(mover, "angle_mort",
                 "#{mover.ship_name} se place dans l'angle mort de #{target.ship_name} (#{detail}) : " \
                 "seuls missiles et torpilles peuvent encore l'atteindre", target)
    else
      log_action(mover, "angle_mort", "#{mover.ship_name} rate l'angle mort de #{target.ship_name} (#{detail})", target)
    end

    mover.update!(movement_action_used: true)
    broadcast_full_update
    render json: { success: true, won: result[:winner] == :attacker, summary: detail }
  end

  def override_position
    position_record = @combat.ship_combat_positions.find(params[:position_id])
    position_record.update!(position: params[:new_position], blind_spot_for_id: nil)

    log_action(position_record.participant_a, "position_override",
               "Position forcée par le MJ : #{position_record.participant_a.ship_name} / " \
               "#{position_record.participant_b.ship_name} -> #{position_record.position_label}",
               position_record.participant_b)

    broadcast_full_update
    render json: { success: true }
  end

  # --- Tir ------------------------------------------------------------------

  def fire_weapon
    attacker = @combat.space_combat_participants.find(params[:attacker_id])
    target = @combat.space_combat_participants.find(params[:target_id])
    return unless authorize!(attacker)

    weapon = find_weapon(attacker, params[:weapon_id])
    return render json: { success: false, error: "Arme introuvable" }, status: :not_found unless weapon

    result = SpaceCombatAttack.new(combat: @combat, attacker: attacker, target: target,
                                   weapon: weapon, gunner: current_user).call

    unless result.success?
      return render json: { success: false, error: result.error }, status: :unprocessable_entity
    end

    result.entries.each { |entry| log_action(attacker, entry[:type], entry[:message], entry[:target]) }
    attacker.update!(offensive_action_used: true)
    ShipCombatPosition.find_pair(@combat.id, attacker.id, target.id)&.update!(engaged: true)

    broadcast_full_update
    render json: { success: true, hit: result.hit?, hp_lost: result.hp_lost, summary: result.summary }
  end

  # Rayon tracteur : action offensive, jet de pilotage opposé
  def tractor_beam
    attacker = @combat.space_combat_participants.find(params[:attacker_id])
    target = @combat.space_combat_participants.find(params[:target_id])
    return unless authorize!(attacker)
    return if block_if_ionized(attacker)

    if attacker.offensive_action_used?
      return render json: { success: false, error: "Action offensive déjà utilisée" }, status: :unprocessable_entity
    end

    atk_m, atk_b = attacker.piloting_dice(current_user)
    def_m, def_b = target.piloting_dice
    result = SpaceCombatRules.opposed_roll(atk_m, atk_b, def_m, def_b)
    detail = "#{SpaceCombatRules.format_roll(result[:attacker])} vs #{SpaceCombatRules.format_roll(result[:defender])}"

    if result[:winner] == :attacker
      position_record = ShipCombatPosition.find_pair(@combat.id, attacker.id, target.id)
      position_record&.update!(position: position_record.absolute_position_for(attacker, :poursuivant),
                               blind_spot_for_id: nil)
      target.update!(movement_action_used: true)
      log_action(attacker, "rayon_tracteur",
                 "#{attacker.ship_name} accroche #{target.ship_name} au rayon tracteur (#{detail}) : " \
                 "plus de mouvement possible pour la cible ce tour", target)
    else
      log_action(attacker, "rayon_tracteur",
                 "#{attacker.ship_name} rate son rayon tracteur sur #{target.ship_name} (#{detail})", target)
    end

    attacker.update!(offensive_action_used: true)
    broadcast_full_update
    render json: { success: true, won: result[:winner] == :attacker, summary: detail }
  end

  # --- Défense --------------------------------------------------------------

  # Action défensive supplémentaire (contre-mesures, objet défensif) : -1D cumulatif
  def countermeasure
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)

    participant.update!(defense_malus: participant.defense_malus + 1)
    log_action(participant, "esquive",
               "#{participant.ship_name} déclenche une action défensive supplémentaire " \
               "(malus cumulé : -#{participant.defense_malus}D sur ses jets de défense)")

    broadcast_full_update
    render json: { success: true }
  end

  # --- Actions d'équipage ---------------------------------------------------

  def repair
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)
    return if block_if_ionized(participant)

    if participant.repair_used?
      return render json: { success: false, error: "Une seule réparation par tour du pilote" },
                    status: :unprocessable_entity
    end
    if participant.ship.hp_current.to_i >= participant.ship.hp_max.to_i
      return render json: { success: false, error: "Le vaisseau est intact" }, status: :unprocessable_entity
    end

    mode = params[:mode].presence || "kit"
    restored, detail = mode == "components" ? repair_with_components : repair_with_kit
    return render json: { success: false, error: detail }, status: :unprocessable_entity if restored.nil?

    participant.update!(pending_repair: participant.pending_repair + restored, repair_used: true)
    log_action(participant, "reparation",
               "#{participant.ship_name} : réparation d'urgence #{detail} -> +#{restored} PB " \
               "au début du prochain tour")

    broadcast_full_update
    render json: { success: true, summary: detail }
  end

  # Jet de commandement du capitaine : +1 par seuil de 5 à tous les jets du vaisseau
  def command
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)
    return if block_if_ionized(participant)

    if participant.command_used?
      return render json: { success: false, error: "Le capitaine a déjà donné ses ordres ce tour" },
                    status: :unprocessable_entity
    end

    mastery, bonus = SpaceCombatStats.user_dice(current_user, "Commandement")
    roll = SpaceCombatRules.roll(mastery, bonus)
    command_bonus = SpaceCombatRules.command_bonus_for(roll[:total])
    participant.update!(captain_bonus: command_bonus, command_used: true)

    log_action(participant, "commandement",
               "#{current_user.username} commande #{participant.ship_name} : " \
               "#{SpaceCombatRules.format_roll(roll)} -> +#{command_bonus} à tous les postes ce tour")

    broadcast_full_update
    render json: { success: true, bonus: command_bonus }
  end

  # Ingénieur radar : détecter un vaisseau furtif
  def detect
    participant = @combat.space_combat_participants.find(params[:participant_id])
    target = @combat.space_combat_participants.find(params[:target_id])
    return unless authorize!(participant)
    return if block_if_ionized(participant)

    mastery, bonus = SpaceCombatStats.add(
      SpaceCombatStats.user_dice(current_user, "Systèmes"),
      SpaceCombatStats.sensor_dice(participant.ship)
    )
    roll = SpaceCombatRules.roll(mastery, bonus + participant.captain_bonus)
    success = roll[:total] >= DETECTION_DIFFICULTY
    target.update!(detected: true) if success

    log_action(participant, "detection",
               "Senseurs de #{participant.ship_name} sur #{target.ship_name} : " \
               "#{SpaceCombatRules.format_roll(roll)} (#{DETECTION_DIFFICULTY}) -> " \
               "#{success ? 'cible détectée' : 'rien au radar'}", target)

    broadcast_full_update
    render json: { success: true, detected: success }
  end

  def toggle_stealth
    participant = @combat.space_combat_participants.find(params[:participant_id])
    participant.update!(stealth: !participant.stealth, detected: false)

    log_action(participant, "furtif",
               "#{participant.ship_name} : mode furtif #{participant.stealth? ? 'activé' : 'désactivé'}")
    broadcast_full_update
    render json: { success: true }
  end

  # --- Fuite et hyperespace (règle 4-8) -------------------------------------

  def flee
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)

    enemies = enemies_of(participant)
    if enemies.empty?
      return render json: { success: false, error: "Aucun ennemi en vue" }, status: :unprocessable_entity
    end

    unless enemies.all? { |enemy| participant.position_with(enemy)&.out_of_range? }
      return render json: { success: false, error: "Il faut d'abord être hors de portée de tous les ennemis" },
                    status: :unprocessable_entity
    end

    participant.update!(movement_action_used: true)
    piloting = contested_against(participant, enemies, :piloting_dice)
    unless piloting[:won]
      log_action(participant, "fuite", "#{participant.ship_name} rate sa manœuvre de fuite (#{piloting[:detail]})")
      broadcast_full_update
      return render json: { success: true, won: false, summary: piloting[:detail] }
    end

    speed = contested_against(participant, enemies, :speed_roll_dice)
    if speed[:won]
      participant.update!(has_fled: true)
      log_action(participant, "fuite",
                 "#{participant.ship_name} sème ses poursuivants et quitte le combat " \
                 "(pilotage #{piloting[:detail]} / vitesse #{speed[:detail]})")
    else
      log_action(participant, "fuite",
                 "#{participant.ship_name} décroche mais reste rattrapable " \
                 "(pilotage #{piloting[:detail]} / vitesse #{speed[:detail]})")
    end

    broadcast_full_update
    render json: { success: true, won: speed[:won], summary: speed[:detail] }
  end

  def start_astrogation
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)
    return if block_if_ionized(participant)

    if participant.ship.hyperdrive_broken?
      return render json: { success: false, error: "Hyperdrive hors service" }, status: :unprocessable_entity
    end
    if participant.astrogation_started?
      return render json: { success: false, error: "Un calcul d'astrogation est déjà en cours" },
                    status: :unprocessable_entity
    end

    mastery, bonus = SpaceCombatStats.user_dice(current_user, "Astrogation")
    roll = SpaceCombatRules.roll(mastery, bonus + participant.captain_bonus)
    turns = SpaceCombatRules.astrogation_turns_needed(roll[:total])
    trace = SpaceCombatRules.trace_difficulty(roll[:total])

    participant.update!(astrogation_started: true, astrogation_turns: turns, hyperspace_ready: false)
    log_action(participant, "hyperespace",
               "#{current_user.username} calcule l'astrogation de #{participant.ship_name} : " \
               "#{SpaceCombatRules.format_roll(roll)} -> #{turns} tour(s) de préparation, " \
               "#{trace.zero? ? 'traçage possible' : "#{trace} seuil(s) contre le traçage"}. " \
               "Tout tir encaissé interrompt le calcul.")

    broadcast_full_update
    render json: { success: true, turns: turns }
  end

  def hyperspace_jump
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)

    unless participant.hyperspace_ready?
      return render json: { success: false, error: "Le calcul d'astrogation n'est pas terminé" },
                    status: :unprocessable_entity
    end

    participant.update!(has_fled: true, astrogation_started: false, hyperspace_ready: false)
    log_action(participant, "hyperespace", "#{participant.ship_name} passe en hyperespace et quitte le combat")

    broadcast_full_update
    render json: { success: true }
  end

  # --- Statistiques et statuts ---------------------------------------------

  def update_stat
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)

    field = params[:field].to_s
    allowed = mj? ? %w[hp_current hp_max] : %w[hp_current]
    unless allowed.include?(field)
      return render json: { success: false, error: "Champ invalide" }, status: :bad_request
    end

    ship = participant.participant
    old_value = ship.send(field)
    new_value = params[:value].to_i

    if ship.update(field => new_value)
      ship.update!(ship_destroyed: false) if field == "hp_current" && new_value.positive? && ship.ship_destroyed?
      log_action(participant, new_value > old_value ? "bouclier" : "degats",
                 "#{ship.name} : #{field == 'hp_max' ? 'PB max' : 'PB'} #{old_value} -> #{new_value}")
      broadcast_full_update
      render json: { success: true }
    else
      render json: { success: false, errors: ship.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_damage_flag
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)

    flag = params[:flag].to_s
    unless Ship::COMBAT_DAMAGE_FLAGS.include?(flag)
      return render json: { success: false, error: "Flag invalide" }, status: :bad_request
    end

    ship = participant.participant
    new_value = !ship.send(flag)
    ship.update!(flag => new_value)
    apply_flag_side_effects(participant, flag, new_value)

    log_action(participant, "flag_damage",
               "#{ship.name} : #{Ship::DAMAGE_FLAG_LABELS[flag]} #{new_value ? 'activé' : 'désactivé'}")

    broadcast_full_update
    render json: { success: true }
  end

  # --- Tours ----------------------------------------------------------------

  def end_turn
    participant = @combat.space_combat_participants.find(params[:participant_id])
    return unless authorize!(participant)

    participant.update!(has_played: true)
    log_action(participant, "fin_tour", "#{participant.ship_name} termine son tour")

    advanced = false
    if @combat.all_played?
      advance_turn!
      advanced = true
    end

    broadcast_full_update
    render json: { success: true, turn_advanced: advanced }
  end

  def next_turn
    advance_turn!
    broadcast_full_update
    render json: { success: true }
  end

  def end_combat
    @combat.space_combat_participants.enemies.each do |participant|
      participant.participant.destroy if participant.participant.is_a?(EnemyShip)
    end

    @combat.space_combat_actions.destroy_all
    @combat.ship_combat_positions.destroy_all
    @combat.space_combat_participants.destroy_all
    @combat.update!(active: false)

    flash[:notice] = "Combat spatial terminé."
    redirect_to mj? ? mj_dashboard_path : space_combat_path
  end

  private

  # --- Helpers de contexte --------------------------------------------------

  def set_current_user
    Current.user = current_user
  end

  def set_combat
    @combat = SpaceCombatState.active_combat.first
    return if @combat

    if request.format.json?
      render json: { success: false, error: "Aucun combat actif" }, status: :not_found
    else
      redirect_to space_combat_path, alert: "Aucun combat actif."
    end
  end

  def mj?
    current_user&.group&.name == "MJ"
  end

  def require_mj!
    return if mj?

    if request.format.json?
      render json: { success: false, error: "Réservé au MJ" }, status: :forbidden
    else
      redirect_to space_combat_path, alert: "Action réservée au MJ."
    end
  end

  def authorize!(participant)
    return true if participant.controlled_by?(current_user)

    render json: { success: false, error: "Vous ne faites pas partie de l'équipage de ce vaisseau" },
           status: :forbidden
    false
  end

  def block_if_ionized(participant)
    return false unless participant.ionized?

    render json: { success: false, error: "Commandes ionisées : seules les actions de mouvement sont possibles" },
           status: :unprocessable_entity
    true
  end

  def ordered_participants(combat)
    combat.space_combat_participants
          .includes(:participant)
          .order(Arel.sql("action_order ASC NULLS LAST, initiative_roll DESC NULLS LAST"))
  end

  def movement_context
    mover = @combat.space_combat_participants.find(params[:mover_id])
    target = @combat.space_combat_participants.find(params[:target_id])
    return [nil, nil, nil] unless authorize!(mover)

    if mover.adrift?
      render json: { success: false, error: "Propulseurs détruits : le vaisseau part à la dérive" },
             status: :unprocessable_entity
      return [nil, nil, nil]
    end

    if mover.movement_action_used?
      render json: { success: false, error: "Action de mouvement déjà utilisée ce tour" },
             status: :unprocessable_entity
      return [nil, nil, nil]
    end

    position_record = ShipCombatPosition.find_pair(@combat.id, mover.id, target.id)
    unless position_record
      render json: { success: false, error: "Pas de position entre ces vaisseaux" }, status: :bad_request
      return [nil, nil, nil]
    end

    [mover, target, position_record]
  end

  def enemies_of(participant)
    @combat.space_combat_participants.in_play.reject { |other| other.allied_with?(participant) }
  end

  # Jet opposé contre plusieurs adversaires : il faut tous les battre
  def contested_against(participant, opponents, dice_method)
    mastery, bonus = participant.public_send(dice_method, current_user)
    roll = SpaceCombatRules.roll(mastery, bonus)

    details = opponents.map do |opponent|
      opp_mastery, opp_bonus = opponent.public_send(dice_method)
      opponent_roll = SpaceCombatRules.roll(opp_mastery, opp_bonus)
      { name: opponent.ship_name, total: opponent_roll[:total], roll: opponent_roll }
    end

    best = details.max_by { |detail| detail[:total] }
    {
      won: roll[:total] > best[:total],
      detail: "#{SpaceCombatRules.format_roll(roll)} vs #{best[:name]} #{SpaceCombatRules.format_roll(best[:roll])}"
    }
  end

  def find_weapon(participant, weapon_id)
    SpaceCombatStats.weapons_for(participant.ship).find { |weapon| weapon.id == weapon_id.to_i }
  end

  # --- Réparation -----------------------------------------------------------

  def repair_with_kit
    kit = current_user.user_inventory_objects.joins(:inventory_object)
                      .find_by(inventory_objects: { name: "Kit de réparation" })
    return [nil, "Aucun kit de réparation dans votre inventaire"] if kit.nil? || kit.quantity.to_i < 1

    mastery, bonus = SpaceCombatStats.user_dice(current_user, "Réparation")
    roll = SpaceCombatRules.roll(mastery, bonus)
    restored = roll[:total] / SpaceCombatRules::REPAIR_DIVISOR
    kit.decrement!(:quantity)

    [restored, "kit de réparation, jet #{SpaceCombatRules.format_roll(roll)} / 2"]
  end

  def repair_with_components
    requested = params[:amount].to_i
    return [nil, "Indiquez un nombre de composants"] unless requested.positive?

    components = current_user.user_inventory_objects.joins(:inventory_object)
                             .find_by(inventory_objects: { name: "Composant" })
    return [nil, "Composants insuffisants"] if components.nil? || components.quantity.to_i < requested

    components.decrement!(:quantity, requested)
    [requested, "#{requested} composant(s) — 1 PB par composant"]
  end

  # --- Statuts --------------------------------------------------------------

  def apply_flag_side_effects(participant, flag, enabled)
    case flag
    when "shields_disabled"
      participant.update!(shields_down_until_turn: enabled ? @combat.turn + 1 : nil)
    when "thrusters_damaged"
      participant.update!(thruster_hits: enabled ? participant.thruster_hits + 1 : 0)
    when "depressurized"
      participant.update!(depressurized_since_turn: enabled ? @combat.turn : nil)
    end
  end

  # --- Passage au tour suivant ---------------------------------------------

  def advance_turn!
    @combat.update!(turn: @combat.turn + 1)
    log_turn_entries = []

    @combat.space_combat_participants.includes(:participant).each do |participant|
      log_turn_entries.concat(upkeep_for(participant))
      participant.reset_turn!
    end

    first_participant = @combat.space_combat_participants.first
    log_action(first_participant, "tour", "— Tour #{@combat.turn} —")
    log_turn_entries.each { |entry| log_action(entry[:participant], entry[:type], entry[:message]) }
  end

  def upkeep_for(participant)
    entries = []
    ship = participant.ship

    if participant.pending_repair.positive?
      restored = [participant.pending_repair, ship.hp_max.to_i - ship.hp_current.to_i].min
      restored = 0 if restored.negative?
      ship.update!(hp_current: ship.hp_current.to_i + restored)
      entries << { participant: participant, type: "reparation",
                   message: "#{participant.ship_name} : +#{restored} PB réparés (#{ship.hp_current}/#{ship.hp_max})" }
      participant.update!(pending_repair: 0)
    end

    shields_back = participant.shields_down_until_turn && @combat.turn >= participant.shields_down_until_turn
    if ship.shields_disabled? && shields_back
      ship.update!(shields_disabled: false)
      participant.update!(shields_down_until_turn: nil)
      entries << { participant: participant, type: "bouclier",
                   message: "#{participant.ship_name} : écrans rechargés" }
    end

    if participant.astrogation_started? && participant.astrogation_turns.positive?
      remaining = participant.astrogation_turns - 1
      participant.update!(astrogation_turns: remaining, hyperspace_ready: remaining.zero?)
      entries << { participant: participant, type: "hyperespace",
                   message: remaining.zero? ? "#{participant.ship_name} : astrogation terminée, saut possible" :
                                              "#{participant.ship_name} : astrogation, encore #{remaining} tour(s)" }
    end

    if ship.depressurized? && participant.depressurized_since_turn
      elapsed = @combat.turn - participant.depressurized_since_turn
      if elapsed >= SpaceCombatParticipant::DEPRESSURIZATION_TURNS
        entries << { participant: participant, type: "flag_damage",
                     message: "#{participant.ship_name} : plus d'air à bord, l'équipage sans combinaison suffoque" }
      else
        entries << { participant: participant, type: "flag_damage",
                     message: "#{participant.ship_name} : dépressurisation, " \
                              "#{SpaceCombatParticipant::DEPRESSURIZATION_TURNS - elapsed} tour(s) d'air restants" }
      end
    end

    entries
  end

  # --- Divers ---------------------------------------------------------------

  def enemy_ship_params
    params.require(:enemy_ship).permit(
      :name, :hp_max, :speed_mastery, :speed_bonus,
      :piloting_mastery, :piloting_bonus, :scale, :interception_level,
      :hull_mastery, :hull_bonus, :shield_mastery, :shield_bonus,
      enemy_ship_weapons_attributes: [
        :id, :weapon_type, :damage_mastery, :damage_bonus,
        :aim_mastery, :aim_bonus, :quantity_current, :quantity_max, :_destroy
      ]
    )
  end

  def create_position_pair(participant_player, participant_enemy)
    a_id, b_id = [participant_player.id, participant_enemy.id].sort
    ShipCombatPosition.find_or_create_by!(
      space_combat_state_id: @combat.id,
      participant_a_id: a_id,
      participant_b_id: b_id
    )
  end

  def log_action(actor_participant, action_type, value, target_participant = nil)
    return if actor_participant.nil?

    SpaceCombatAction.create!(
      space_combat_state_id: actor_participant.space_combat_state_id,
      actor_participant: actor_participant,
      actor_crew_user: current_user,
      target_participant: target_participant,
      action_type: action_type,
      value: value
    )
  end

  # Le plateau dépend des droits de chacun (MJ, poste d'équipage) : on diffuse
  # donc un rendu par utilisateur, sur son propre canal.
  def broadcast_full_update
    @combat.reload
    participants = ordered_participants(@combat).to_a
    positions = @combat.ship_combat_positions.includes(:participant_a, :participant_b).to_a

    User.joins(:group).where(groups: { name: %w[PJ MJ] }).find_each do |user|
      Turbo::StreamsChannel.broadcast_replace_to(
        SpaceCombatState.stream_for_user(user),
        target: "space_combat_main",
        partial: "space_combat/combat_board",
        locals: {
          combat: @combat,
          participants: participants,
          positions: positions,
          current_user: user
        }
      )
    end
  end
end
