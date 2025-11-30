class LightSaber < ApplicationRecord
  belongs_to :apprentice, optional: true

  validates :name, presence: true
  validates :color, presence: true
  validates :crystal, presence: true
  validates :damage, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :damage_bonus, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Couleurs de lame disponibles
  COLORS = {
    "bleu" => { hex: "#4FC3F7", glow: "rgba(79, 195, 247, 0.8)", label: "Bleu" },
    "vert" => { hex: "#66BB6A", glow: "rgba(102, 187, 106, 0.8)", label: "Vert" },
    "violet" => { hex: "#AB47BC", glow: "rgba(171, 71, 188, 0.8)", label: "Violet" },
    "jaune" => { hex: "#FFEE58", glow: "rgba(255, 238, 88, 0.8)", label: "Jaune" },
    "orange" => { hex: "#FFA726", glow: "rgba(255, 167, 38, 0.8)", label: "Orange" },
    "blanc" => { hex: "#FFFFFF", glow: "rgba(255, 255, 255, 0.9)", label: "Blanc" },
    "rouge" => { hex: "#EF5350", glow: "rgba(239, 83, 80, 0.8)", label: "Rouge" },
    "noir" => { hex: "#1a1a1a", glow: "rgba(255, 255, 255, 0.3)", label: "Noir (Sabre obscur)" }
  }.freeze

  # Cristaux connus
  CRYSTALS = [
    "Cristal Kyber",
    "Cristal Kyber synthétique",
    "Cristal d'Ilum",
    "Cristal de Dantooine",
    "Cristal Adegan",
    "Cristal Krayt Dragon Pearl",
    "Cristal Hurrikaine",
    "Cristal de Solari",
    "Cristal de Mantle of the Force",
    "Cristal Heart of the Guardian",
    "Cristal corrompu"
  ].freeze

  # Attributs spéciaux possibles
  SPECIAL_ATTRIBUTES = [
    "Tranchant amélioré",
    "Lame instable",
    "Double lame",
    "Garde croisée",
    "Lame courte (Shoto)",
    "Pique laser",
    "Canne-sabre",
    "Sabre à double phase",
    "Lame tournante (Inquisiteur)",
    "Résistance au Cortosis"
  ].freeze

  # Retourne les informations de couleur
  def color_info
    COLORS[color] || COLORS["bleu"]
  end

  def color_hex
    color_info[:hex]
  end

  def color_glow
    color_info[:glow]
  end

  def color_label
    color_info[:label]
  end

  # Dégâts totaux
  def total_damage
    damage + damage_bonus
  end

  # Affichage des dégâts
  def damage_display
    if damage_bonus > 0
      "#{damage}D+#{damage_bonus}"
    else
      "#{damage}D"
    end
  end

  # Vérifie si le sabre a un attribut spécial
  def has_special_attribute?
    special_attribute.present?
  end
end

