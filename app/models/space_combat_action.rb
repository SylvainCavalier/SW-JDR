class SpaceCombatAction < ApplicationRecord
  belongs_to :space_combat_state
  belongs_to :actor_participant, class_name: "SpaceCombatParticipant"
  belongs_to :actor_crew_user, class_name: "User", optional: true
  belongs_to :target_participant, class_name: "SpaceCombatParticipant", optional: true

  ACTION_TYPES = %w[
    initiative mouvement tir esquive degats bouclier
    flag_damage position_override fin_tour
  ].freeze

  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }

  after_create :broadcast_action

  private

  def broadcast_action
    Turbo::StreamsChannel.broadcast_append_to(
      "space_combat_updates",
      target: "space_combat_log",
      partial: "space_combat/combat_action",
      locals: { action: self }
    )
  end
end
