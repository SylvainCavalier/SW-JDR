class SpaceCombatState < ApplicationRecord
  has_many :space_combat_participants, dependent: :destroy
  has_many :ship_combat_positions, dependent: :destroy
  has_many :space_combat_actions, dependent: :destroy

  scope :active_combat, -> { where(active: true) }

  def current_participant
    space_combat_participants
      .where(has_played: false)
      .where.not(action_order: nil)
      .order(:action_order)
      .first
  end

  def all_played?
    space_combat_participants.where.not(action_order: nil).all?(&:has_played?)
  end
end
