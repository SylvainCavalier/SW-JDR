class ShipsSkill < ApplicationRecord
  belongs_to :ship
  belongs_to :skill

  validates :mastery, numericality: { only_integer: true }, allow_nil: true
  validates :bonus, numericality: { only_integer: true }, allow_nil: true
end
