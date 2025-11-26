class Building < ApplicationRecord
  belongs_to :headquarter
  belongs_to :chief_pet, class_name: 'Pet', optional: true
  has_many :building_pets, dependent: :destroy
  has_many :pets, through: :building_pets

  validates :name, presence: true
  validates :level, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :update_building_details

  BUILDING_DATA = YAML.load_file(Rails.root.join("config/catalogs/buildings.yml"))

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
