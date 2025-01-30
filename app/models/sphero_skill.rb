class SpheroSkill < ApplicationRecord
  belongs_to :sphero
  belongs_to :skill

  validates :mastery, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :bonus, numericality: { only_integer: true }
end