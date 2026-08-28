class SpaceCombatParticipant < ApplicationRecord
  belongs_to :space_combat_state
  belongs_to :participant, polymorphic: true

  MAX_THRUSTER_HITS = 3
  DEPRESSURIZATION_TURNS = 3

  scope :by_initiative, -> { order(Arel.sql("initiative_roll DESC NULLS LAST")) }
  scope :players, -> { where(side: 0) }
  scope :enemies, -> { where(side: 1) }
  scope :in_play, -> { where(has_fled: false) }

  delegate :hp_current, :hp_max, to: :ship

  def ship
    participant
  end

  def ship_name
    participant.name
  end

  def player?
    side.zero?
  end

  def enemy?
    !player?
  end

  def allied_with?(other)
    side == other.side
  end

  def player_ship?
    ship.is_a?(Ship)
  end

  # --- Équipage -------------------------------------------------------------

  def crew_members
    return CrewMember.none unless player_ship?

    ship.crew_members.includes(:assignable)
  end

  def crew_users
    crew_members.select { |member| member.assignable.is_a?(User) }
  end

  def pilot_user
    crew_members.find { |m| m.position == "Pilote" && m.assignable.is_a?(User) }&.assignable ||
      crew_members.find { |m| m.position == "Copilote" && m.assignable.is_a?(User) }&.assignable
  end

  def crew_position_for(user)
    return nil unless user

    crew_members.find { |m| m.assignable_type == "User" && m.assignable_id == user.id }&.position
  end

  def captain_user
    crew_members.find { |m| %w[Capitaine].include?(m.position) && m.assignable.is_a?(User) }&.assignable ||
      crew_members.find { |m| m.position == "Second du capitaine" && m.assignable.is_a?(User) }&.assignable
  end

  # Un joueur peut agir sur ce vaisseau s'il fait partie de l'équipage.
  # À défaut d'équipage assigné, tout le groupe propriétaire peut le manœuvrer.
  def controlled_by?(user)
    return false unless user
    return true if user.group&.name == "MJ"
    return false unless player? && player_ship?
    return true if crew_position_for(user).present?

    crew_members.none? { |m| m.assignable_type == "User" } && ship.group_id == user.group_id
  end

  # --- État du vaisseau -----------------------------------------------------

  # Attention : ne pas nommer cette méthode `destroyed?`, qui appartient à
  # ActiveRecord et empêcherait toute sauvegarde du participant.
  def wrecked?
    ship.ship_destroyed? || ship.hp_current.to_i <= 0
  end

  def out_of_combat?
    wrecked? || has_fled?
  end

  def adrift?
    thruster_hits >= MAX_THRUSTER_HITS
  end

  def ionized?
    ship.controls_ionized?
  end

  def has_shields?
    mastery, bonus = SpaceCombatStats.ship_dice(ship, :shields)
    mastery.positive? || bonus.positive?
  end

  def shields_active?
    has_shields? && !ship.shields_disabled?
  end

  def scale_value
    SpaceCombatStats.scale_value(ship)
  end

  def big_ship?
    scale_value >= 3
  end

  def small_ship?
    scale_value <= 1
  end

  # --- Jets -----------------------------------------------------------------

  def speed_dice
    SpaceCombatStats.ship_dice(ship, :speed)
  end

  # Maniabilité du vaisseau, amputée de 1D par propulseur touché
  def handling_dice
    mastery, bonus = SpaceCombatStats.ship_dice(ship, :piloting)
    [[mastery - thruster_hits, 0].max, bonus]
  end

  def hull_dice
    SpaceCombatStats.ship_dice(ship, :hull)
  end

  def shield_dice
    return [0, 0] unless shields_active?

    SpaceCombatStats.ship_dice(ship, :shields)
  end

  # Jet de pilotage : maniabilité du vaisseau + compétence du pilote
  def piloting_dice(user = nil)
    pilot = user || pilot_user
    mastery, bonus = SpaceCombatStats.add(handling_dice, SpaceCombatStats.user_dice(pilot, "Pilotage"))
    [mastery, bonus + captain_bonus]
  end

  # Jet d'esquive spatiale, malus cumulatif de -1D par action défensive du tour
  def evasion_dice(user = nil)
    pilot = user || pilot_user
    mastery, bonus = SpaceCombatStats.add(handling_dice, SpaceCombatStats.user_dice(pilot, "Esquive spatiale"))
    [[mastery - defense_malus, 0].max, bonus + captain_bonus]
  end

  def speed_roll_dice(user = nil)
    pilot = user || pilot_user
    mastery, bonus = SpaceCombatStats.add(speed_dice, SpaceCombatStats.user_dice(pilot, "Pilotage"))
    [mastery, bonus + captain_bonus]
  end

  # --- Tour -----------------------------------------------------------------

  def reset_turn!
    update!(
      offensive_action_used: false,
      movement_action_used: false,
      has_played: false,
      defense_malus: 0,
      repair_used: false,
      command_used: false,
      captain_bonus: 0
    )
  end

  def position_with(other)
    ShipCombatPosition.find_pair(space_combat_state_id, id, other.id)
  end

  def positions
    ShipCombatPosition.where(space_combat_state_id: space_combat_state_id)
                      .where("participant_a_id = :id OR participant_b_id = :id", id: id)
  end

  def status_summary
    labels = ship.status_labels.dup
    labels << "À la dérive" if adrift?
    labels << "En fuite" if has_fled?
    labels
  end
end
