class SpaceCombatState < ApplicationRecord
  has_many :space_combat_participants, dependent: :destroy
  has_many :ship_combat_positions, dependent: :destroy
  has_many :space_combat_actions, dependent: :destroy

  scope :active_combat, -> { where(active: true) }

  # Le plateau est rendu différemment selon les droits : un canal Turbo par joueur.
  def self.stream_for_user(user)
    "space_combat_user_#{user&.id}"
  end

  LOG_STREAM = "space_combat_updates".freeze

  def active_participants
    space_combat_participants.reject(&:out_of_combat?)
  end

  def current_participant
    active_participants
      .select { |participant| !participant.has_played? && participant.action_order.present? }
      .min_by(&:action_order)
  end

  def all_played?
    engaged = active_participants.select { |participant| participant.action_order.present? }
    engaged.any? && engaged.all?(&:has_played?)
  end
end
