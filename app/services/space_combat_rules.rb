class SpaceCombatRules
  WEAPON_MATRIX = ShipCombatPosition::WEAPON_MATRIX

  def self.can_fire?(relative_position, weapon_type)
    matrix = WEAPON_MATRIX[relative_position.to_sym]
    return false unless matrix
    matrix[weapon_type.to_sym] || false
  end

  # +1D si poursuivant, 0 sinon
  def self.aim_bonus_dice(relative_position)
    relative_position.to_sym == :poursuivant ? 1 : 0
  end

  def self.roll_dice(number_of_dice, sides = 6)
    rolls = Array.new(number_of_dice) { rand(1..sides) }
    { individual: rolls, total: rolls.sum }
  end

  def self.opposed_roll(atk_mastery, atk_bonus, def_mastery, def_bonus)
    atk_result = roll_dice(atk_mastery)
    atk_total = atk_result[:total] + atk_bonus

    def_result = roll_dice(def_mastery)
    def_total = def_result[:total] + def_bonus

    winner = atk_total >= def_total ? :attacker : :defender
    margin = (atk_total - def_total).abs

    {
      attacker: { rolls: atk_result[:individual], bonus: atk_bonus, total: atk_total },
      defender: { rolls: def_result[:individual], bonus: def_bonus, total: def_total },
      winner: winner,
      margin: margin
    }
  end
end
