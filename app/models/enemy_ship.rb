class EnemyShip < ApplicationRecord
  has_many :enemy_ship_weapons, dependent: :destroy
  accepts_nested_attributes_for :enemy_ship_weapons, allow_destroy: true

  validates :name, presence: true
  validates :hp_max, numericality: { greater_than_or_equal_to: 0 }
  validates :speed_mastery, :speed_bonus, :piloting_mastery, :piloting_bonus,
            :hull_mastery, :hull_bonus, :shield_mastery, :shield_bonus,
            numericality: { greater_than_or_equal_to: 0 }
  validates :scale, inclusion: { in: 0..5 }
  validates :interception_level, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 12 }

  after_initialize :set_defaults, if: :new_record?

  SCALE_NAMES = {
    0 => "Très petit",
    1 => "Petit",
    2 => "Moyen",
    3 => "Grand",
    4 => "Très grand",
    5 => "Gigantesque"
  }.freeze

  def scale_name
    SCALE_NAMES[scale] || "Inconnu"
  end

  def status_labels
    labels = Ship::COMBAT_DAMAGE_FLAGS.select { |flag| send(flag) }.map { |flag| Ship::DAMAGE_FLAG_LABELS[flag] }
    labels.empty? ? ["Intact"] : labels
  end

  def hull_dice_label
    format_dice(hull_mastery, hull_bonus)
  end

  def shield_dice_label
    format_dice(shield_mastery, shield_bonus)
  end

  def has_shields?
    shield_mastery.to_i.positive? || shield_bonus.to_i.positive?
  end

  private

  def set_defaults
    self.hp_current = hp_max if hp_current.zero? && hp_max.positive?
  end

  def format_dice(mastery, bonus)
    bonus.to_i.positive? ? "#{mastery}D+#{bonus}" : "#{mastery}D"
  end
end
