class HeadquarterInventoryObject < ApplicationRecord
  belongs_to :headquarter
  belongs_to :inventory_object

  # Ajout d'une quantité pour gérer le stockage des objets
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
end
