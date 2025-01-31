class EnemySkill < ApplicationRecord
  belongs_to :enemy
  belongs_to :skill

  validates :mastery, :bonus, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :skill_id, presence: true

  accepts_nested_attributes_for :skill
end
