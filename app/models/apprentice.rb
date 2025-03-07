class Apprentice < ApplicationRecord
  belongs_to :user
  belongs_to :pet
  has_many :pet_skills, through: :pet
  has_many :skills, through: :pet_skills

  validates :jedi_name, presence: true
  validates :side, numericality: { only_integer: true, greater_than_or_equal_to: -100, less_than_or_equal_to: 100 }
  validates :speciality, inclusion: { in: ["Commun", "Gardien", "Consulaire", "Sentinelle"] }
  validates :midi_chlorians, numericality: { only_integer: true, greater_than_or_equal_to: 5000, less_than_or_equal_to: 20000 }
end
