class Group < ApplicationRecord
  has_many :users

  def has_permission?(permission)
    permissions.include?(permission)
  end
end
