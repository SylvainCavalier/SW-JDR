# Accès unifié aux dés des vaisseaux (Ship / EnemyShip) et de leur équipage.
# Un jet est toujours représenté par un couple [mastery (nombre de D6), bonus].
module SpaceCombatStats
  module_function

  SHIP_SKILL_NAMES = {
    speed: "Vitesse",
    piloting: "Maniabilité",
    hull: "Coque",
    shields: "Ecrans"
  }.freeze

  ENEMY_COLUMNS = {
    speed: %i[speed_mastery speed_bonus],
    piloting: %i[piloting_mastery piloting_bonus],
    hull: %i[hull_mastery hull_bonus],
    shields: %i[shield_mastery shield_bonus]
  }.freeze

  # Dés propres au vaisseau (indépendants de l'équipage)
  def ship_dice(ship, key)
    if ship.is_a?(EnemyShip)
      mastery_col, bonus_col = ENEMY_COLUMNS.fetch(key)
      [ship.send(mastery_col).to_i, ship.send(bonus_col).to_i]
    else
      skill = ship.ships_skills.joins(:skill).find_by(skills: { name: SHIP_SKILL_NAMES.fetch(key) })
      [skill&.mastery.to_i, skill&.bonus.to_i]
    end
  end

  # Dés d'une compétence de PJ (0 si le PJ ne l'a pas)
  def user_dice(user, skill_name)
    return [0, 0] unless user

    skill = user.user_skills.joins(:skill).find_by(skills: { name: skill_name })
    [skill&.mastery.to_i, skill&.bonus.to_i]
  end

  def add(*pairs)
    pairs.compact.reduce([0, 0]) { |(m, b), (dm, db)| [m + dm.to_i, b + db.to_i] }
  end

  # Échelle numérique 0..5, quel que soit le type de vaisseau
  def scale_value(ship)
    return ship.scale.to_i if ship.is_a?(EnemyShip)

    Ship.scales[ship.scale].to_i
  end

  def big_ship?(ship)
    scale_value(ship) >= 3
  end

  def small_ship?(ship)
    scale_value(ship) <= 1
  end

  def weapons_for(ship)
    if ship.is_a?(EnemyShip)
      ship.enemy_ship_weapons.to_a
    else
      ship.ship_weapons.where(weapon_type: SpaceCombatRules::KNOWN_WEAPON_TYPES).to_a
    end
  end

  def weapon_label(weapon)
    return weapon.name if weapon.respond_to?(:name) && weapon.name.present?

    weapon.weapon_type.capitalize
  end

  def unlimited_ammo?(weapon)
    weapon.quantity_max.nil? || weapon.quantity_max.to_i.zero?
  end

  def ammo_left(weapon)
    return nil if unlimited_ammo?(weapon)

    weapon.quantity_current.to_i
  end

  # Dés de senseurs du vaisseau (ingénieur radar / détection de vaisseaux furtifs)
  def sensor_dice(ship)
    return [0, 0] if ship.is_a?(EnemyShip)

    skill = ship.ships_skills.joins(:skill).find_by(skills: { name: "Senseurs détection" })
    [skill&.mastery.to_i, skill&.bonus.to_i]
  end

  # Nombre de canons encore opérationnels (règle « canon touché »)
  def canon_count(ship)
    weapons_for(ship).count { |w| SpaceCombatRules.normalize_weapon_type(w.weapon_type) == :canon }
  end
end
