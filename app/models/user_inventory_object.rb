class UserInventoryObject < ApplicationRecord
  belongs_to :user
  belongs_to :inventory_object
end
