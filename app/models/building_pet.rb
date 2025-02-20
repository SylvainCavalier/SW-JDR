class BuildingPet < ApplicationRecord
  belongs_to :building
  belongs_to :pet
end
