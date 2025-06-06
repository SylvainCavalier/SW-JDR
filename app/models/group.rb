class Group < ApplicationRecord
  has_many :users
  has_many :ships

  def has_permission?(permission)
    permissions.include?(permission)
  end
end
