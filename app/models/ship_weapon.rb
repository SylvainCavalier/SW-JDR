class ShipWeapon < ApplicationRecord
  belongs_to :ship

  validates :name, presence: true
  validates :damage_upgrade_level, :aim_upgrade_level, 
            inclusion: { in: 0..3, message: "doit être entre 0 et 3" }

  # Configuration des améliorations d'armes
  UPGRADE_COSTS = [0, 200, 600, 2000].freeze # Coûts pour chaque niveau (0, 1, 2, 3)
  UPGRADE_BONUSES = {
    1 => { bonus: 1, mastery: 0 },    # +1
    2 => { bonus: 2, mastery: 0 },    # +2  
    3 => { bonus: 0, mastery: 1 }     # +1D
  }.freeze

  # Méthodes pour les améliorations de dégâts
  def can_upgrade_damage?
    damage_upgrade_level < 3
  end

  def damage_upgrade_cost
    return 0 unless can_upgrade_damage?
    UPGRADE_COSTS[damage_upgrade_level + 1]
  end

  def can_afford_damage_upgrade?(user_credits)
    can_upgrade_damage? && user_credits >= damage_upgrade_cost
  end

  def upgrade_damage!
    return false unless can_upgrade_damage?
    
    new_level = damage_upgrade_level + 1
    upgrade_info = UPGRADE_BONUSES[new_level]
    
    self.damage_upgrade_level = new_level
    self.damage_bonus += upgrade_info[:bonus]
    self.damage_mastery += upgrade_info[:mastery]
    
    save!
  end

  # Méthodes pour les améliorations de précision
  def can_upgrade_aim?
    aim_upgrade_level < 3
  end

  def aim_upgrade_cost
    return 0 unless can_upgrade_aim?
    UPGRADE_COSTS[aim_upgrade_level + 1]
  end

  def can_afford_aim_upgrade?(user_credits)
    can_upgrade_aim? && user_credits >= aim_upgrade_cost
  end

  def upgrade_aim!
    return false unless can_upgrade_aim?
    
    new_level = aim_upgrade_level + 1
    upgrade_info = UPGRADE_BONUSES[new_level]
    
    self.aim_upgrade_level = new_level
    self.aim_bonus += upgrade_info[:bonus]
    self.aim_mastery += upgrade_info[:mastery]
    
    save!
  end

  # Méthodes utilitaires
  def damage_upgrade_description
    return "MAX" unless can_upgrade_damage?
    next_level = damage_upgrade_level + 1
    upgrade_info = UPGRADE_BONUSES[next_level]
    
    if upgrade_info[:mastery] > 0
      "+#{upgrade_info[:mastery]}D"
    else
      "+#{upgrade_info[:bonus]}"
    end
  end

  def aim_upgrade_description
    return "MAX" unless can_upgrade_aim?
    next_level = aim_upgrade_level + 1
    upgrade_info = UPGRADE_BONUSES[next_level]
    
    if upgrade_info[:mastery] > 0
      "+#{upgrade_info[:mastery]}D"
    else
      "+#{upgrade_info[:bonus]}"
    end
  end
end
