module SpaceCombatHelper
  def space_action_color(action)
    case action.action_type
    when "degats"
      "#ff4444"
    when "bouclier"
      "#33b5e5"
    when "tir"
      "#ff8800"
    when "mouvement"
      "#17a2b8"
    when "esquive"
      "#aa66cc"
    when "initiative"
      "#ffbb33"
    when "ajout"
      "#00C851"
    when "fin_tour"
      "#aaaaaa"
    when "flag_damage"
      "#ff4444"
    when "position_override"
      "#17a2b8"
    else
      "#ffffff"
    end
  end

  def position_badge_color(position)
    case position
    when "out_of_range"
      "secondary"
    when "a_pursues_b", "b_pursues_a"
      "warning"
    when "face_to_face"
      "danger"
    when "parallel"
      "info"
    else
      "light"
    end
  end

  # SVG diagram helpers for position lines

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

  def format_dice(mastery, bonus)
    mastery = mastery.to_i
    bonus = bonus.to_i
    bonus.positive? ? "#{mastery}D+#{bonus}" : "#{mastery}D"
  end
end
