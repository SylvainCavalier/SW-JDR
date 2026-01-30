class EnemyShipWeapon < ApplicationRecord
  belongs_to :enemy_ship

  WEAPON_TYPES = %w[canon tourelle missile torpille special].freeze

  validates :name, presence: true
  validates :weapon_type, presence: true, inclusion: { in: WEAPON_TYPES }
  validates :damage_mastery, :damage_bonus, :aim_mastery, :aim_bonus,
            numericality: { greater_than_or_equal_to: 0 }

  def canon?
    weapon_type == "canon"
  end

  def tourelle?
    weapon_type == "tourelle"
  end

  def missile?
    weapon_type == "missile"
  end

  def torpille?
    weapon_type == "torpille"
  end

  def special?
    weapon_type == "special"
  end
end
