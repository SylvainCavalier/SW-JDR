module ShipsHelper
  # Retourne une liste d'avaries à afficher dans la vue.
  # Désormais, on affiche une seule cause persistée jusqu'à réparation complète.
  def ship_damage_list(ship)
    return [] unless ship.hp_current && ship.hp_max
    return [] if ship.hp_current >= ship.hp_max

    cause = ship.current_damage_cause.to_s.strip
    cause.present? ? [cause] : []
  end
end