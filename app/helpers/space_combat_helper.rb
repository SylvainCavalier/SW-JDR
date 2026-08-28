module SpaceCombatHelper
  ACTION_COLORS = {
    "degats" => "#ff4444",
    "bouclier" => "#33b5e5",
    "tir" => "#ff8800",
    "mouvement" => "#17a2b8",
    "esquive" => "#aa66cc",
    "initiative" => "#ffbb33",
    "ajout" => "#00C851",
    "retrait" => "#aaaaaa",
    "fin_tour" => "#aaaaaa",
    "tour" => "#ffffff",
    "flag_damage" => "#ff4444",
    "position_override" => "#17a2b8",
    "reparation" => "#00C851",
    "commandement" => "#ffbb33",
    "fuite" => "#aa66cc",
    "hyperespace" => "#33b5e5",
    "furtif" => "#9e9e9e",
    "detection" => "#33b5e5",
    "angle_mort" => "#aa66cc",
    "rayon_tracteur" => "#ff8800",
    "coup_decisif" => "#ff1744"
  }.freeze

  def space_action_color(action)
    ACTION_COLORS.fetch(action.action_type, "#ffffff")
  end

  def position_badge_color(position)
    case position
    when "out_of_range" then "secondary"
    when "a_pursues_b", "b_pursues_a" then "warning"
    when "face_to_face" then "danger"
    when "parallel" then "info"
    else "light"
    end
  end

  # --- Diagramme SVG --------------------------------------------------------

  def position_line_color(relative_position)
    case relative_position
    when :poursuivant then "#17a2b8"
    when :poursuivi then "#ff8800"
    when :face_a_face then "#dc3545"
    when :vol_parallele then "#ffc107"
    when :hors_de_portee then "#6c757d"
    else "#ffffff"
    end
  end

  def position_line_dash(relative_position)
    case relative_position
    when :vol_parallele then "8,4"
    when :hors_de_portee then "4,4"
    else "none"
    end
  end

  def position_line_opacity(relative_position)
    relative_position == :hors_de_portee ? "0.5" : "1"
  end

  def position_arrow_markers(relative_position)
    case relative_position
    when :poursuivant then { marker_end: "url(#arrow-cyan)" }
    when :poursuivi then { marker_start: "url(#arrow-orange)" }
    when :face_a_face then { marker_start: "url(#arrow-red)", marker_end: "url(#arrow-red)" }
    else {}
    end
  end

  # --- Dés ------------------------------------------------------------------

  def format_dice(mastery, bonus)
    mastery = mastery.to_i
    bonus = bonus.to_i
    bonus.zero? ? "#{mastery}D" : "#{mastery}D#{format('%+d', bonus)}"
  end

  def dice_label(pair)
    format_dice(pair[0], pair[1])
  end

  def relative_position_label(relative_position)
    ShipCombatPosition::RELATIVE_LABELS[relative_position] || "—"
  end

  def relative_position_badge_color(relative_position)
    case relative_position
    when :poursuivant then "success"
    when :poursuivi then "warning"
    when :face_a_face then "danger"
    when :vol_parallele then "info"
    else "secondary"
    end
  end

  # Peut-on tirer avec cette arme sur cette cible ? Renvoie [bool, raison]
  def weapon_shot_state(combat, attacker, target, weapon)
    position = ShipCombatPosition.find_pair(combat.id, attacker.id, target.id)
    return [false, "Pas de position"] unless position

    relative = position.relative_position_for(attacker)
    type = SpaceCombatRules.normalize_weapon_type(weapon.weapon_type)

    return [false, "Cible furtive non détectée"] if target.stealth? && !target.detected?
    return [false, "Cible hors combat"] if target.out_of_combat?
    return [false, "Angle mort"] if position.blind_spot_for?(target) && !%i[missile torpille].include?(type)

    ammo = SpaceCombatStats.ammo_left(weapon)
    return [false, "Plus de munitions"] if ammo && ammo <= 0

    unless SpaceCombatRules.can_fire?(relative, weapon.weapon_type)
      return [false, "Impossible en #{relative_position_label(relative).downcase}"]
    end

    [true, nil]
  end

  def ammo_label(weapon)
    ammo = SpaceCombatStats.ammo_left(weapon)
    return nil unless ammo

    "#{ammo}/#{weapon.quantity_max}"
  end

  def crew_position_badge(participant, user)
    position = participant.crew_position_for(user)
    return nil if position.blank?

    position
  end
end
