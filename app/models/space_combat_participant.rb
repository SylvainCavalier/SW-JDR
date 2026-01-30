class SpaceCombatParticipant < ApplicationRecord
  belongs_to :space_combat_state
  belongs_to :participant, polymorphic: true

  scope :by_initiative, -> { order(Arel.sql("initiative_roll DESC NULLS LAST")) }
  scope :players, -> { where(side: 0) }
  scope :enemies, -> { where(side: 1) }

  def ship_name
    participant.name
  end

  def allied_with?(other)
    side == other.side
  end

  def reset_turn!
    update!(
      offensive_action_used: false,
      movement_action_used: false,
      has_played: false,
      defense_malus: 0
    )
  end

  def position_with(other)
    ShipCombatPosition.find_pair(space_combat_state_id, id, other.id)
  end
end
