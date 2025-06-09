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

  enum scale: {
    very_small: 0,
    small: 1,
    medium: 2,
    big: 3,
    very_big: 4,
    gigantic: 5
  }

  validates :name, presence: true
  validates :model, presence: true
  validate :used_capacity_cannot_exceed_capacity

  before_create :set_initial_hp
  before_validation :set_scale_and_capacity_from_size
  after_save :update_parent_used_capacity, if: :saved_change_to_parent_ship_id?

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

  # Retourne la capacité occupée si ce vaisseau est embarqué
  def embarked_capacity
    case scale.to_sym
    when :very_small then 1
    when :small then 2
    when :medium then 6
    when :big then 14
    else 0
    end
  end

  # Peut-il être embarqué ?
  def can_be_embarked?
    return false if parent_ship_id.present? # Ne peut pas être embarqué s'il est déjà embarqué
    return false if scale.to_sym == :very_big || scale.to_sym == :gigantic # Les très gros vaisseaux ne peuvent pas être embarqués
    true
  end

  # Peut-il embarquer d'autres vaisseaux ?
  def can_embark_ships?
    capacity > 0
  end

  # Met à jour la capacité utilisée en fonction des vaisseaux embarqués
  def update_used_capacity!
    new_used_capacity = child_ships.sum(&:embarked_capacity)
    update_column(:used_capacity, new_used_capacity)
  end

  # Vérifie si un vaisseau peut être embarqué dans ce vaisseau
  def can_embark_ship?(ship)
    return false unless can_embark_ships?
    return false unless ship.can_be_embarked?
    used_capacity + ship.embarked_capacity <= capacity
  end

  private

  def set_initial_hp
    self.hp_current = hp_max if hp_max.present?
  end

  # Déduit l'échelle et la capacité à partir de la taille (size)
  def set_scale_and_capacity_from_size
    return if size.blank?
    meters = size.to_i
    case meters
    when 0..9
      self.scale = :very_small
      self.capacity = 0
    when 10..19
      self.scale = :small
      self.capacity = 0
    when 20..49
      self.scale = :medium
      self.capacity = 2
    when 50..99
      self.scale = :big
      self.capacity = 8
    when 100..299
      self.scale = :very_big
      self.capacity = 20
    else
      self.scale = :gigantic
      self.capacity = 50
    end
  end

  def used_capacity_cannot_exceed_capacity
    if used_capacity > capacity
      errors.add(:used_capacity, "ne peut pas dépasser la capacité maximale (#{capacity})")
    end
  end

  def update_parent_used_capacity
    if parent_ship_id_before_last_save.present?
      old_parent = Ship.find_by(id: parent_ship_id_before_last_save)
      old_parent&.update_used_capacity!
    end
    if parent_ship_id.present?
      parent_ship.update_used_capacity!
    end
  end
end
