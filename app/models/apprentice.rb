class Apprentice < ApplicationRecord
  belongs_to :user
  belongs_to :pet
  has_many :pet_skills, through: :pet
  has_many :skills, through: :pet_skills

  validates :name, presence: true
end
