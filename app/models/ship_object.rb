class ShipObject < ApplicationRecord
  belongs_to :ship

  validates :name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
