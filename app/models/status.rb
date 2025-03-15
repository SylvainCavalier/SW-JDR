class Status < ApplicationRecord
  has_many :user_statuses, dependent: :destroy
  has_many :users, through: :user_statuses

  has_many :pet_statuses, dependent: :destroy
  has_many :pets, through: :pet_statuses
end
