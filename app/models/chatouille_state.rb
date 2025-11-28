class ChatouilleState < ApplicationRecord
  belongs_to :user

  # Validations
  validates :faith_points, numericality: { greater_than_or_equal_to: 0 }
  validates :missionaries, numericality: { greater_than_or_equal_to: 0 }
  validates :religion_credits, numericality: { greater_than_or_equal_to: 0 }
  validates :market_share, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :political_influence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :current_step, inclusion: { in: 1..4 }

  # Seuils de parts de marché pour les étapes
  STEP_THRESHOLDS = {
    1 => { min: 0, max: 5, name: "Fondation" },
    2 => { min: 5, max: 20, name: "Expansion régionale" },
    3 => { min: 20, max: 30, name: "Influence majeure" },
    4 => { min: 30, max: 100, name: "Expansion interplanétaire" }
  }.freeze

  # Religions concurrentes sur Mirial (pour le graphique)
  COMPETING_RELIGIONS = [
    { name: "Culte des Ancêtres", color: "#6B8E23", base_share: 25 },
    { name: "Ordre du Soleil Levant", color: "#FFD700", base_share: 20 },
    { name: "Fraternité de la Paix", color: "#4682B4", base_share: 18 },
    { name: "Temple des Esprits", color: "#9370DB", base_share: 15 },
    { name: "Cercle de la Nature", color: "#228B22", base_share: 12 },
    { name: "Autres cultes mineurs", color: "#808080", base_share: 9 }
  ].freeze

  # Couleur de Monsieur Chatouille
  CHATOUILLE_COLOR = "#FF6B35"

  # Charger les événements depuis le fichier YAML
  def self.events
    @events ||= YAML.load_file(Rails.root.join("config", "catalogs", "chatouille.yml"))["events"]
  end

  # Obtenir les événements pour l'étape actuelle
  def available_events
    self.class.events.select { |e| e["step"] == current_step }
  end

  # Obtenir l'événement en cours
  def current_event
    return nil unless current_event_index
    available_events[current_event_index]
  end

  # Choisir un événement aléatoire non encore complété
  def pick_random_event
    available = available_events.each_with_index.reject do |event, index|
      completed_events.include?("#{current_step}_#{index}")
    end
    
    return nil if available.empty?
    
    event, index = available.sample
    update!(current_event_index: index, event_available: true)
    event
  end

  # Résoudre un événement avec un choix
  def resolve_event(choice_index)
    return nil unless current_event && event_available
    
    choice = current_event["choices"][choice_index]
    return nil unless choice

    # Marquer l'événement comme complété
    completed = completed_events.dup
    completed << "#{current_step}_#{current_event_index}"
    
    # Appliquer les effets du choix
    effects = apply_choice_effects(choice)
    
    update!(
      completed_events: completed,
      current_event_index: nil,
      event_available: false
    )
    
    check_step_progression
    
    { choice: choice, effects: effects }
  end

  # Appliquer les effets d'un choix
  def apply_choice_effects(choice)
    effects = choice["effects"] || default_effects_for_choice(choice["text"])
    
    self.faith_points += effects["faith"] || 0
    self.missionaries += effects["missionaries"] || 0
    self.religion_credits += effects["credits"] || 0
    self.market_share += effects["market_share"] || 0
    self.political_influence += effects["influence"] || 0
    self.temples_count += effects["temples"] || 0
    self.total_converts += effects["converts"] || 0
    
    # S'assurer que les valeurs restent dans les limites
    self.faith_points = [faith_points, 0].max
    self.missionaries = [missionaries, 0].max
    self.religion_credits = [religion_credits, 0].max
    self.market_share = [[market_share, 0].max, 100].min
    self.political_influence = [[political_influence, 0].max, 100].min
    
    save!
    effects
  end

  # Effets par défaut basés sur le texte du choix
  def default_effects_for_choice(text)
    effects = { "market_share" => rand(0.2..0.8).round(2) }
    
    if text.downcase.include?("coût foi")
      effects["faith"] = -rand(2..5)
    elsif text.downcase.include?("coût crédit") || text.downcase.include?("coût : crédit")
      effects["credits"] = -rand(20..50)
    elsif text.downcase.include?("+crédit") || text.downcase.include?("gain crédit") || text.downcase.include?("gain de crédit")
      effects["credits"] = rand(10..30)
    elsif text.downcase.include?("+influence") || text.downcase.include?("gain influence")
      effects["influence"] = rand(2..5)
    elsif text.downcase.include?("+fidèles") || text.downcase.include?("gain fidèles")
      effects["market_share"] += rand(0.3..0.7).round(2)
      effects["converts"] = rand(10..50)
    elsif text.downcase.include?("bonus foi") || text.downcase.include?("gain foi")
      effects["faith"] = rand(2..5)
    end
    
    effects
  end

  # Vérifier si on doit passer à l'étape suivante
  def check_step_progression
    threshold = STEP_THRESHOLDS[current_step]
    
    if market_share >= threshold[:max] && current_step < 4
      update!(current_step: current_step + 1)
      send_progression_notification
    end
  end

  # Calculer les parts de marché des autres religions
  def competing_shares
    remaining = 100 - market_share
    total_base = COMPETING_RELIGIONS.sum { |r| r[:base_share] }
    
    COMPETING_RELIGIONS.map do |religion|
      share = (religion[:base_share].to_f / total_base * remaining).round(2)
      religion.merge(share: share)
    end
  end

  # Données pour le graphique camembert
  def market_chart_data
    data = [{ name: "Monsieur Chatouille", share: market_share, color: CHATOUILLE_COLOR }]
    data + competing_shares
  end

  # Nom de l'étape actuelle
  def step_name
    STEP_THRESHOLDS[current_step][:name]
  end

  # Progression vers la prochaine étape (en %)
  def step_progress
    threshold = STEP_THRESHOLDS[current_step]
    range = threshold[:max] - threshold[:min]
    progress = market_share - threshold[:min]
    [(progress / range * 100).round, 100].min
  end

  # Actions disponibles selon l'étape (crédits rééquilibrés selon l'univers Star Wars)
  # Échelle : 5cr = bière, 100cr = medipack, 500cr = blaster, 10000cr = arme rare, 20000cr = maison, 50000cr = vaisseau
  def available_actions
    actions = {
      1 => [
        { id: "convince", name: "Convaincre des fidèles", cost: { faith: 2 }, effect: { market_share: 0.3, converts: 5 } },
        { id: "public_ritual", name: "Rituel public", cost: { faith: 3 }, effect: { market_share: 0.5, converts: 10 } }
      ],
      2 => [
        { id: "convince", name: "Convaincre des fidèles", cost: { faith: 2 }, effect: { market_share: 0.3, converts: 5 } },
        { id: "public_ritual", name: "Rituel public", cost: { faith: 3 }, effect: { market_share: 0.5, converts: 10 } },
        { id: "build_temple", name: "Construire un temple", cost: { credits: 8000, missionaries: 1 }, effect: { market_share: 1.0, converts: 20 } },
        { id: "sacred_writings", name: "Publier des écrits sacrés", cost: { faith: 5, credits: 500 }, effect: { market_share: 0.8 } },
        { id: "anti_heretic_militia", name: "Créer une milice anti-hérétique", cost: { credits: 3000, missionaries: 2 }, effect: { influence: 3 } }
      ],
      3 => [
        { id: "council_lobbying", name: "Lobbying au Conseil", cost: { credits: 5000, faith: 5 }, effect: { influence: 10 } },
        { id: "send_missionaries", name: "Envoyer des missionnaires (autres planètes)", cost: { missionaries: 2, credits: 15000 }, effect: { market_share: 2.0 } },
        { id: "minor_cult_alliance", name: "Alliance avec cultes mineurs", cost: { faith: 10 }, effect: { market_share: 1.5, influence: 5 } }
      ],
      4 => [
        { id: "tickle_crusade", name: "Croisade chatouilleuse", cost: { missionaries: 5, credits: 50000, faith: 20 }, effect: { market_share: 5.0, converts: 200, influence: 15 } },
        { id: "galactic_expansion", name: "Expansion galactique", cost: { missionaries: 3, credits: 30000 }, effect: { market_share: 3.0 } },
        { id: "miracle", name: "Miracle public", cost: { faith: 30 }, effect: { market_share: 4.0, converts: 100, influence: 10 } }
      ]
    }
    
    # Retourne toutes les actions jusqu'à l'étape actuelle
    (1..current_step).flat_map { |step| actions[step] || [] }
  end

  # Exécuter une action
  def perform_action(action_id)
    action = available_actions.find { |a| a[:id] == action_id }
    return { success: false, error: "Action non disponible" } unless action
    
    # Vérifier les ressources
    cost = action[:cost]
    if cost[:faith] && faith_points < cost[:faith]
      return { success: false, error: "Pas assez de points de foi" }
    end
    if cost[:credits] && religion_credits < cost[:credits]
      return { success: false, error: "Pas assez de crédits" }
    end
    if cost[:missionaries] && missionaries < cost[:missionaries]
      return { success: false, error: "Pas assez de missionnaires" }
    end
    
    # Déduire les coûts
    self.faith_points -= cost[:faith] || 0
    self.religion_credits -= cost[:credits] || 0
    self.missionaries -= cost[:missionaries] || 0
    
    # Appliquer les effets
    effect = action[:effect]
    self.market_share += effect[:market_share] || 0
    self.total_converts += effect[:converts] || 0
    self.political_influence += effect[:influence] || 0
    
    # Cas spéciaux
    if action_id == "build_temple"
      self.temples_count += 1
    end
    
    save!
    check_step_progression
    
    { success: true, action: action }
  end

  # Envoyer une notification de progression
  def send_progression_notification
    Holonew.create!(
      sender: User.find_by(group: Group.find_by(name: "MJ")) || user,
      title: "🎉 Nouvelle étape atteinte !",
      content: "Ô grande Chatouille Cosmique ! Notre religion a atteint l'étape '#{step_name}' ! De nouvelles possibilités s'ouvrent à nous !",
      target_user: user.id,
      sender_alias: "Kessar le Prophète"
    )
  end

  # Formater une expression de Kessar aléatoire
  def kessar_expression
    %w[amazed happy upset].sample
  end
end

