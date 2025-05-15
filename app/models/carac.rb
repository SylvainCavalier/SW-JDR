class Carac < ApplicationRecord
  has_many :skills
  has_many :user_caracs, dependent: :destroy
  has_many :users, through: :user_caracs

end
