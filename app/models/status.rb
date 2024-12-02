class Status < ApplicationRecord
  has_many :user_statuses, dependent: :destroy
  has_many :users, through: :user_statuses
end
