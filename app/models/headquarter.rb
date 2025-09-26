class Headquarter < ApplicationRecord
  self.table_name = "headquarters"
  has_one_attached :image

  # Relation avec les objets de l'inventaire via la table de jointure
  has_many :headquarter_inventory_objects, dependent: :destroy
  has_many :inventory_objects, through: :headquarter_inventory_objects
  has_many :building_pets, through: :buildings
  has_many :pets, through: :building_pets

  # Relation avec les bâtiments
  has_many :buildings, dependent: :destroy
  has_many :defenses, dependent: :destroy

  # Bonus temporaires de PV max en fonction des niveaux de bâtiments
  # Dortoirs: niveau 2 => +2, niveau 3 => +3, niveau 4 => +4
  # Refuge animalier: niveau 3 => +3
  def dormitories_level
    buildings.where(category: "Dortoirs").order(level: :desc).limit(1).pluck(:level).first.to_i
  end

  def animal_refuge_level
    buildings.where(category: "Refuge animalier").order(level: :desc).limit(1).pluck(:level).first.to_i
  end

  def temporary_hp_bonus_for_users
    case dormitories_level
    when 4 then 4
    when 3 then 3
    when 2 then 2
    else 0
    end
  end

  def temporary_hp_bonus_for_humanoid_pets
    temporary_hp_bonus_for_users
  end

  def temporary_hp_bonus_for_animal_pets
    case animal_refuge_level
    when 3 then 3
    else 0
    end
  end
end
