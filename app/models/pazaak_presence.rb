class PazaakPresence < ApplicationRecord
  belongs_to :user

  scope :recent, -> { where("last_seen_at > ?", 30.seconds.ago) }

  def self.touch!(user)
    presence = find_or_initialize_by(user: user)
    presence.last_seen_at = Time.current
    presence.save!
  end
end


