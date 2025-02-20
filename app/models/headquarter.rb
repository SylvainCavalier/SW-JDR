class Headquarter < ApplicationRecord
  self.table_name = "headquarters"
  has_one_attached :image

  # Relation avec les objets de l'inventaire via la table de jointure
  has_many :headquarter_inventory_objects, dependent: :destroy
  has_many :inventory_objects, through: :headquarter_inventory_objects

  # Relation avec les bâtiments
  has_many :buildings, dependent: :destroy
end
