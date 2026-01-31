class ApprenticeSkill < ApplicationRecord
  belongs_to :apprentice
  belongs_to :skill

  validates :mastery, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 15 }
  validates :bonus, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 15 }
  validates :skill_id, uniqueness: { scope: :apprentice_id }
  validates :talent, inclusion: { in: %w[ordinaire sous_doue talentueux genial], allow_nil: true }

  # Constantes pour les talents
  TALENTS = {
    "ordinaire" => { 
      chance: 50, label: "Ordinaire", icon: "fa-circle", color: "#888888", 
      success_modifier: 0, double_bonus_chance: 0,
      quotes: [] # Pas de message pour ordinaire
    },
    "sous_doue" => { 
      chance: 20, label: "Sous-doué", icon: "fa-arrow-down", color: "#E53935", 
      success_modifier: -10, double_bonus_chance: 0,
      quotes: [
        "Maître, je crois que je ne suis vraiment pas doué pour ça...",
        "Je ne comprends pas... ça me semble si difficile.",
        "Peut-être que ce n'est pas fait pour moi, Maître.",
        "J'ai du mal à ressentir la Force dans cet exercice...",
        "Je sens que je vais devoir travailler dur sur ce point."
      ]
    },
    "talentueux" => { 
      chance: 25, label: "Talentueux", icon: "fa-star", color: "#4FC3F7", 
      success_modifier: 10, double_bonus_chance: 50,
      quotes: [
        "Maître, je sens que je suis fait pour ça !",
        "C'est comme si la Force me guidait naturellement !",
        "Je ressens une connexion particulière avec cette discipline.",
        "Ça me semble... familier. Comme si je l'avais toujours su.",
        "La Force coule en moi quand je pratique ceci !"
      ]
    },
    "genial" => { 
      chance: 5, label: "Génial", icon: "fa-crown", color: "#FFD700", 
      success_modifier: 20, double_bonus_chance: 100,
      quotes: [
        "Maître ! Je vois tout clairement ! C'est... incroyable !",
        "La Force... elle chante en moi quand je fais ça !",
        "Je n'ai jamais ressenti quelque chose d'aussi puissant !",
        "C'est comme si j'étais né pour maîtriser cette compétence !",
        "Maître, regardez ! C'est si naturel pour moi !"
      ]
    }
  }.freeze

  # Révèle le talent lors du premier entraînement
  # Si le MJ a pré-défini le talent, on le révèle simplement
  # Sinon, on le génère aléatoirement puis on le révèle
  def discover_talent!
    return talent if talent_revealed? # Déjà révélé au joueur

    if talent.present?
      # Le MJ avait pré-défini le talent, on le révèle maintenant
      update!(talent_revealed: true)
    else
      # Génération aléatoire du talent (pondérée par le potentiel midi-chlorien)
      weights = apprentice.midi_chlorian_modifiers[:talent_weights]
      roll = rand(1..100)
      cumulative = 0

      discovered = weights.find do |key, chance|
        cumulative += chance
        roll <= cumulative
      end&.first || "ordinaire"

      update!(talent: discovered, talent_revealed: true)
    end
    
    talent
  end

  # Vérifie si le talent a été révélé au joueur (après le premier entraînement)
  def talent_discovered?
    talent_revealed?
  end

  # Vérifie si le talent a été pré-défini par le MJ (mais pas encore révélé)
  def talent_predefined?
    talent.present? && !talent_revealed?
  end

  # Informations sur le talent (pour l'affichage au joueur)
  def talent_info
    return nil unless talent_discovered?
    TALENTS[talent]
  end

  # Informations sur le talent réel (pour les calculs, même si pas révélé)
  def actual_talent_info
    return nil unless talent.present?
    TALENTS[talent]
  end

  def talent_label
    talent_info&.dig(:label) || "Inconnu"
  end

  def talent_icon
    talent_info&.dig(:icon) || "fa-question"
  end

  def talent_color
    talent_info&.dig(:color) || "#888888"
  end

  # Modificateur de réussite basé sur le talent (utilise le talent réel, même si pas révélé)
  def success_modifier
    actual_talent_info&.dig(:success_modifier) || 0
  end

  # Chance de gagner +2 au lieu de +1 (utilise le talent réel, même si pas révélé)
  def double_bonus_chance
    actual_talent_info&.dig(:double_bonus_chance) || 0
  end

  # Affichage formaté de la valeur
  def display_value
    bonus > 0 ? "#{mastery}D+#{bonus}" : "#{mastery}D"
  end

  # Citation de découverte de talent (aléatoire)
  def talent_discovery_quote
    return nil unless talent_discovered?
    quotes = talent_info&.dig(:quotes) || []
    quotes.sample
  end

  # Vérifie si le talent a une citation (non-ordinaire)
  def has_talent_quote?
    talent_discovered? && talent != "ordinaire" && talent_info&.dig(:quotes)&.any?
  end
end

