class Enemy < ApplicationRecord
  has_many :enemy_skills, dependent: :destroy
  has_many :skills, through: :enemy_skills

  validates :enemy_type, presence: true
  validates :number, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :hp_current, :hp_max, :shield_current, :shield_max, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: ->(enemy) { Status.pluck(:name) }, message: "problème de validation" }

  accepts_nested_attributes_for :enemy_skills, allow_destroy: true

  after_initialize :set_defaults, if: :new_record?

  def name
    if Enemy.where(enemy_type: enemy_type).count > 1
      "#{enemy_type} #{number}"
    else
      enemy_type
    end
  end

  def current_status
    Status.find_by(name: status)
  end

  def set_status(new_status_name)
    update(status: new_status_name)
  end

  private

  def set_defaults
    self.status ||= "En forme"
  end
end
