class ShipWeapon < ApplicationRecord
  belongs_to :ship

  validates :name, presence: true
end
