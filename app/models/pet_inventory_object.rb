class PetInventoryObject < ApplicationRecord
  belongs_to :pet
  belongs_to :inventory_object
end
