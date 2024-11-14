class UserSkill < ApplicationRecord
  belongs_to :user
  belongs_to :skill

  validates :mastery, inclusion: { in: 0..15 }
  validates :bonus, inclusion: { in: 0..15 }
end
