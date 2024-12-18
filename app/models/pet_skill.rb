class PetSkill < ApplicationRecord
  belongs_to :pet
  belongs_to :skill

  validates :mastery, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :bonus, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end