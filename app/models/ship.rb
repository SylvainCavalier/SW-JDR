class Ship < ApplicationRecord
  belongs_to :group
  belongs_to :parent_ship, class_name: 'Ship', optional: true
  has_many :child_ships, class_name: 'Ship', foreign_key: 'parent_ship_id', dependent: :nullify

  has_one_attached :image

  has_many :ships_skills, dependent: :destroy
  has_many :skills, through: :ships_skills

  has_many :ship_objects, dependent: :destroy

  has_many :ship_weapons, dependent: :destroy

  enum turret: { blaster: 0, plasmique: 1, lourde: 2 }

  validates :name, presence: true
  validates :model, presence: true

  before_create :set_initial_hp

  def status_labels
    labels = []
    labels << "Écrans désactivés" if shields_disabled
    labels << "Commandes ionisées" if controls_ionized
    labels << "Arme endommagée" if weapon_damaged
    labels << "Propulseurs touchés" if thrusters_damaged
    labels << "Hyperdrive HS" if hyperdrive_broken
    labels << "Dépressurisation" if depressurized
    labels << "Vaisseau détruit" if ship_destroyed
    labels = ["Intact"] if labels.empty?
    labels
  end

  private

  def set_initial_hp
    self.hp_current = hp_max if hp_max.present?
  end
end
