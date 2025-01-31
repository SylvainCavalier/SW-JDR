class Enemy < ApplicationRecord
  has_many :enemy_skills, dependent: :destroy
  has_many :skills, through: :enemy_skills

  validates :enemy_type, presence: true
  validates :number, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :hp_current, :hp_max, :shield_current, :shield_max, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: ["En forme", "Empoisonné", "Sonné", "Mort"], message: "problème de validation" }

  accepts_nested_attributes_for :enemy_skills, allow_destroy: true

  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.status ||= "En forme"
  end
end
