class Group < ApplicationRecord
  has_many :users
  has_many :ships
  has_one_attached :image

  def has_permission?(permission)
    permissions.include?(permission)
  end
end
