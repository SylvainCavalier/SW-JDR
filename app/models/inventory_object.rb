class InventoryObject < ApplicationRecord
  has_many :user_inventory_objects
  has_many :users, through: :user_inventory_objects
end
