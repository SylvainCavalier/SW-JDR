class CombatAction < ApplicationRecord
  belongs_to :actor, polymorphic: true
  belongs_to :target, polymorphic: true
  
  validates :action_type, presence: true
  validates :value, presence: true
  
  after_create :broadcast_action
  
  private
  
  def broadcast_action
    Turbo::StreamsChannel.broadcast_append_to(
      "combat_updates",
      target: "combat_log",
      partial: "pages/combat_action",
      locals: { combat_action: self }
    )
  end
end 