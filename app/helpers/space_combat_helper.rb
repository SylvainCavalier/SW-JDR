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
end
