class Skill < ApplicationRecord
  has_many :user_skills
  has_many :users, through: :user_skills
  has_many :pet_skills, dependent: :destroy
  has_many :pets, through: :pet_skills
  has_many :sphero_skills, dependent: :destroy
  has_many :spheros, through: :sphero_skills
  has_many :enemy_skills, dependent: :destroy
  has_many :enemies, through: :enemy_skills

  validates :name, presence: true, uniqueness: true
end
