class Skill < ApplicationRecord
  has_many :user_skills
  has_many :users, through: :user_skills
  has_many :pet_skills, dependent: :destroy
  has_many :pets, through: :pet_skills

  validates :name, presence: true, uniqueness: true
end
