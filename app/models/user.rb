class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:username]
  belongs_to :group
  belongs_to :race, optional: true
  belongs_to :classe_perso, class_name: "ClassePerso", foreign_key: "classe_perso_id", optional: true
  belongs_to :pet, optional: true
  has_many :user_inventory_objects
  has_many :inventory_objects, through: :user_inventory_objects
  has_many :user_skills
  has_many :skills, through: :user_skills
  has_many :user_statuses, dependent: :destroy
  has_many :statuses, through: :user_statuses

  validates :username, presence: true, uniqueness: true
  validates :hp_current, numericality: { greater_than_or_equal_to: -20 }
  validate :shield_current_values_valid

  after_update_commit :broadcast_xp_update, if: :saved_change_to_xp?
  after_update :update_status_based_on_hp

  attr_accessor :medicine_mastery, :medicine_bonus
  attr_accessor :res_corp_mastery, :res_corp_bonus

  def set_status(status_name = nil)
    if status_name.blank?
      status_name = case hp_current
                    when 1..Float::INFINITY then "En forme"
                    when 0 then "Inconscient"
                    when -9..-1 then "Agonisant"
                    else "Mort"
                    end
    end
  
    status = Status.find_by(name: status_name)
    if status
      user_statuses.destroy_all
      user_statuses.create!(status: status)
      broadcast_status_update
    else
      Rails.logger.warn "⚠️ Aucun statut trouvé pour '#{status_name}'."
    end
  end

  def medicine_roll
    medicine_skill = user_skills.includes(:skill).find_by(skills: { name: "Médecine" })
    if medicine_skill.nil?
      Rails.logger.warn "⚠️ Aucun skill de Médecine trouvé pour l'utilisateur #{id}."
      return 0
    end

    mastery = medicine_skill.mastery || 0
    bonus = medicine_skill.bonus || 0
    Rails.logger.debug "🎲 Compétence Médecine - Mastery: #{mastery}, Bonus: #{bonus}"

    (1..mastery).map { rand(1..6) }.sum + bonus
  end

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

  def broadcast_credits_update
    Rails.logger.debug "Broadcasting credits update for user ##{id} on credits_updates_#{id}"
    broadcast_replace_to(
      "credits_updates_#{id}",
      target: "user_#{id}_credits_frame",
      partial: "pages/credits",
      locals: { user: self }
    )
  end

  def broadcast_status_update
    Rails.logger.debug "Broadcasting status update for user ##{id} on status_updates_#{id}"
    broadcast_replace_to(
      "status_updates_#{id}",
      target: "user_#{id}_status_frame",
      partial: "pages/status",
      locals: { user: self }
    )
  end

  def broadcast_hp_update
    Rails.logger.debug "Broadcasting HP update for user ##{id} on hp_updates_#{id}"
    broadcast_replace_to(
      "hp_updates_#{id}",
      target: "user_#{id}_hp_frame",
      partial: "pages/hp_bar",
      locals: { user: self }
    )
  end

  def equip_patch(patch_id)
    update(patch: patch_id)
  end

  def unequip_patch
    update(patch: nil)
  end

  def equipped_patch
    InventoryObject.find_by(id: patch)
  end

  def activate_energy_shield
    return unless can_activate_energy_shield?

    transaction do
      update!(
        shield_state: true,
        echani_shield_state: false
      )
      schedule_shield_deactivation
    end
  end

  def activate_echani_shield
    return unless can_activate_echani_shield?

    transaction do
      update!(
        echani_shield_state: true,
        shield_state: false
      )
      schedule_shield_deactivation
    end
  end

  def deactivate_all_shields
    update!(
      shield_state: false,
      echani_shield_state: false
    )
  end

  def can_activate_energy_shield?
    shield_current.positive? && !shield_state
  end

  def can_activate_echani_shield?
    echani_shield_current.positive? && !echani_shield_state
  end

  def broadcast_energy_shield_update
    Rails.logger.debug "Broadcasting energy shield update for user ##{id}"
    broadcast_replace_to(
      "shields_updates_#{id}",
      target: "user_#{id}_energy_shield_frame",
      partial: "pages/energy_shield_update",
      locals: { user: self }
    )
  end
  
  def broadcast_echani_shield_update
    Rails.logger.debug "Broadcasting echani shield update for user ##{id}"
    broadcast_replace_to(
      "shields_updates_#{id}",
      target: "user_#{id}_echani_shield_frame",
      partial: "pages/echani_shield_update",
      locals: { user: self }
    )
  end

  private

  def update_status_based_on_hp
    if saved_change_to_hp_current?
      set_status
    end
  end

  def shield_current_values_valid
    if shield_current.present? && shield_current.negative?
      errors.add(:shield_current, "ne peut pas être négatif")
    end
  
    if echani_shield_current.present? && echani_shield_current.negative?
      errors.add(:echani_shield_current, "ne peut pas être négatif")
    end
  end

  def schedule_shield_deactivation
    unless shield_state || echani_shield_state
      Rails.logger.info "Aucun bouclier actif, pas besoin de planifier une désactivation."
      return
    end
  
    Rails.logger.info "Désactivation des boucliers temporairement désactivée."
    # DeactivateShieldsJob.set(wait: 30.minutes).perform_later(id)
  end

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
