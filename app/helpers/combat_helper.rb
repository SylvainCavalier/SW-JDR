module CombatHelper
  def action_color(action)
    case action.action_type
    when "damage"
      "#ff4444" # Rouge pour les dégâts
    when "heal"
      "#00C851" # Vert pour les soins
    when "shield"
      "#33b5e5" # Bleu pour les boucliers
    when "status"
      "#aa66cc" # Violet pour les statuts
    else
      "#ffffff" # Blanc par défaut
    end
  end
end 