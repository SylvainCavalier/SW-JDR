class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:username]
  belongs_to :group
  belongs_to :race, optional: true
  belongs_to :classe_perso, class_name: "ClassePerso", foreign_key: "classe_perso_id", optional: true
  has_many :inventory_objects, dependent: :destroy
  has_many :user_skills
  has_many :skills, through: :user_skills

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

  def broadcast_xp_update
    broadcast_replace_to "xp_updates_#{id}", 
                         target: "user_xp_frame", 
                         partial: "pages/user_xp", 
                         locals: { xp: self.xp }
  end
end
