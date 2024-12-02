class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:username]
  belongs_to :group
  belongs_to :race, optional: true
  belongs_to :classe_perso, class_name: "ClassePerso", foreign_key: "classe_perso_id", optional: true
  has_many :user_inventory_objects
  has_many :inventory_objects, through: :user_inventory_objects
  has_many :user_skills
  has_many :skills, through: :user_skills
  has_many :user_statuses, dependent: :destroy
  has_many :statuses, through: :user_statuses

  validates :username, presence: true, uniqueness: true

  after_update_commit :broadcast_xp_update, if: :saved_change_to_xp?

  attr_accessor :medicine_mastery, :medicine_bonus

  def apply_xp_bonus(xp_to_add)
    increment!(:total_xp, xp_to_add)
    increment!(:xp, xp_to_add)

    if human_race? && (total_xp % 10).zero?
      increment!(:xp, 1)
      notify_racial_xp_bonus
    end
  end

  def current_status
    user_statuses.order(created_at: :desc).first&.status
  end

  def broadcast_xp_update
    Rails.logger.debug "Broadcasting XP update for user ##{id}"
    broadcast_replace_to(
      "xp_updates_#{id}",
      target: "user_#{id}_xp_frame",
      partial: "pages/xp_update",
      locals: { user: self }
    )
  end

  private

  def human_race?
    race&.name == "Humain"
  end

  def notify_racial_xp_bonus
    broadcast_append_to "xp_notifications_#{id}",
                        target: "xp_notifications",
                        partial: "users/xp_notification",
                        locals: { message: "+1 XP racial ! 🎉" }
  end
end
