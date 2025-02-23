class Building < ApplicationRecord
  belongs_to :headquarter
  belongs_to :chief_pet, class_name: 'Pet', optional: true
  has_many :building_pets, dependent: :destroy
  has_many :pets, through: :building_pets

  validates :name, presence: true
  validates :level, numericality: { only_integer: true, equal_or_greater_than: 0 }

  before_validation :update_building_details

  BUILDING_DATA = JSON.parse(File.read(Rails.root.join("db/seeds/buildings_data.json")))

  def update_building_details
    return unless BUILDING_DATA[name] && BUILDING_DATA[name][level.to_s]

    data = BUILDING_DATA[name][level.to_s]
    self.name = data["name"]
    self.description = data["description"]
    self.price = data["price"]
    self.properties = data["properties"]
  end

  def property(key)
    properties[key.to_s] || "Non spécifié"
  end
end
