class Pet < ApplicationRecord
  has_many :pet_inventory_objects, dependent: :destroy
  has_many :inventory_objects, through: :pet_inventory_objects

  validates :name, :race, presence: true
end
