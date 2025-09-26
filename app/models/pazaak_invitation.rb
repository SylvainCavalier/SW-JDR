class PazaakInvitation < ApplicationRecord
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User"
  belongs_to :pazaak_game, optional: true

  enum status: { pending: 0, accepted: 1, declined: 2, expired: 3 }

  validates :inviter, :invitee, presence: true
  validate :invitee_not_inviter

  after_create_commit :broadcast_pending

  def invitee_not_inviter
    errors.add(:invitee_id, "ne peut pas être l’inviteur") if inviter_id == invitee_id
  end

  def broadcast_pending
    # Placeholder Turbo Stream broadcast; à affiner avec un canal dédié
  end
end


