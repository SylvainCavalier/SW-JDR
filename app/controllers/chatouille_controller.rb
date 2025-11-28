class ChatouilleController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_chatouille_access!, except: [:trigger_event]
  before_action :set_chatouille_state, except: [:trigger_event]
  before_action :authorize_mj!, only: [:trigger_event]

  # Dashboard principal
  def index
    @market_data = @chatouille_state.market_chart_data
    @available_actions = @chatouille_state.available_actions
  end

  # Page de dialogue avec Kessar (événement en cours)
  def event
    @event = @chatouille_state.current_event
    redirect_to chatouille_path, alert: "Aucun événement en cours." unless @event
  end

  # Résoudre un événement (choisir une option)
  def resolve_event
    choice_index = params[:choice_index].to_i
    result = @chatouille_state.resolve_event(choice_index)
    
    if result
      @choice = result[:choice]
      @effects = result[:effects]
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chatouille_path, notice: "Choix effectué !" }
      end
    else
      redirect_to chatouille_event_path, alert: "Erreur lors de la résolution."
    end
  end

  # Doctrine - Gestion des dogmes
  def doctrine
    @faith_actions = [
      { id: "pray", name: "Prière collective", cost: { faith: 0 }, effect: { faith: 2 }, description: "Organiser une séance de prière pour gagner des points de foi." },
      { id: "sermon", name: "Sermon de Kessar", cost: { faith: 1 }, effect: { market_share: 0.2, converts: 3 }, description: "Kessar prêche la bonne parole chatouillante." },
      { id: "meditation", name: "Méditation chatouilleuse", cost: { faith: 2 }, effect: { faith: 5 }, description: "Séance de méditation profonde pour renforcer la foi." }
    ]
  end

  # Construire - Gestion des temples et infrastructures
  # Échelle : 5cr = bière, 100cr = medipack, 500cr = blaster, 10000cr = arme rare, 20000cr = maison, 50000cr = vaisseau
  def build
    @buildings = [
      { id: "small_temple", name: "Petit temple", cost: { credits: 5000, missionaries: 1 }, effect: { temples: 1, market_share: 0.5 }, description: "Un modeste lieu de culte pour les fidèles locaux." },
      { id: "medium_temple", name: "Temple régional", cost: { credits: 15000, missionaries: 2 }, effect: { temples: 1, market_share: 1.5, influence: 3 }, description: "Un temple plus grand avec capacité d'accueil.", available_step: 2 },
      { id: "grand_temple", name: "Grand Temple", cost: { credits: 40000, missionaries: 3 }, effect: { temples: 1, market_share: 3.0, influence: 8 }, description: "Monument à la gloire de Monsieur Chatouille.", available_step: 3 },
      { id: "training_center", name: "Centre de formation", cost: { credits: 8000 }, effect: { missionaries: 2 }, description: "Former de nouveaux missionnaires.", available_step: 2 },
      { id: "propaganda_office", name: "Bureau de propagande", cost: { credits: 3000 }, effect: { market_share: 0.8 }, description: "Diffuser la bonne parole via des affiches et flyers." }
    ].select { |b| (b[:available_step] || 1) <= @chatouille_state.current_step }
  end

  # Marketing - Promotion de la religion
  def marketing
    @campaigns = [
      { id: "flyers", name: "Distribution de flyers", cost: { credits: 100 }, effect: { market_share: 0.3, converts: 5 }, description: "Des tracts avec le visage souriant de Monsieur Chatouille." },
      { id: "event", name: "Événement public", cost: { credits: 500, faith: 3 }, effect: { market_share: 0.8, converts: 15 }, description: "Organiser un rassemblement festif." },
      { id: "holopromo", name: "Campagne holovid", cost: { credits: 2000 }, effect: { market_share: 1.2, converts: 25 }, description: "Spot publicitaire sur l'HoloNet local.", available_step: 2 },
      { id: "celebrity", name: "Parrainage de célébrité", cost: { credits: 10000, faith: 5 }, effect: { market_share: 2.0, converts: 40, influence: 5 }, description: "Une personnalité locale rejoint le culte.", available_step: 3 },
      { id: "galactic_campaign", name: "Campagne galactique", cost: { credits: 50000, missionaries: 2 }, effect: { market_share: 4.0, converts: 100 }, description: "Diffusion dans toute la galaxie.", available_step: 4 }
    ].select { |c| (c[:available_step] || 1) <= @chatouille_state.current_step }
  end

  # Politique - Influence au Conseil
  def politics
    @political_actions = [
      { id: "lobby", name: "Lobbying discret", cost: { credits: 1000 }, effect: { influence: 3 }, description: "Quelques pots-de-vin bien placés." },
      { id: "petition", name: "Pétition populaire", cost: { faith: 5 }, effect: { influence: 5, market_share: 0.3 }, description: "Mobiliser les fidèles pour une cause." },
      { id: "alliance", name: "Alliance temporaire", cost: { credits: 3000, faith: 3 }, effect: { influence: 8 }, description: "S'allier avec un autre culte mineur.", available_step: 2 },
      { id: "council_speech", name: "Discours au Conseil", cost: { faith: 10 }, effect: { influence: 12, market_share: 0.5 }, description: "Kessar prononce un discours mémorable.", available_step: 3, requires: :council_observer },
      { id: "political_maneuver", name: "Manœuvre politique", cost: { credits: 8000, faith: 8 }, effect: { influence: 20 }, description: "Coup politique pour gagner du terrain.", available_step: 4 }
    ].select { |a| 
      step_ok = (a[:available_step] || 1) <= @chatouille_state.current_step
      requires_ok = a[:requires].nil? || @chatouille_state.send(a[:requires])
      step_ok && requires_ok
    }
  end

  # Comptabilité - Gestion des ressources
  # Revenus basés sur l'échelle Star Wars (plus réalistes)
  def accounting
    @income_sources = [
      { name: "Dons des fidèles", amount: (@chatouille_state.total_converts * 2).round, frequency: "par session" },
      { name: "Vente de reliques", amount: @chatouille_state.temples_count * 200, frequency: "par session" },
      { name: "Taxes spirituelles", amount: (@chatouille_state.market_share * 50).round, frequency: "par session" }
    ]
    @total_income = @income_sources.sum { |s| s[:amount] }
  end

  # Exécuter une action
  def perform_action
    action_type = params[:action_type]
    action_id = params[:action_id]
    
    # Trouver l'action dans les différentes catégories
    action = find_action(action_type, action_id)
    
    unless action
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("action-result", partial: "chatouille/action_error", locals: { error: "Action non trouvée" }) }
        format.html { redirect_back fallback_location: chatouille_path, alert: "Action non trouvée" }
      end
      return
    end
    
    result = execute_action(action)
    
    respond_to do |format|
      if result[:success]
        format.turbo_stream { render turbo_stream: turbo_stream_updates(result) }
        format.html { redirect_back fallback_location: chatouille_path, notice: "Action réussie !" }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("action-result", partial: "chatouille/action_error", locals: { error: result[:error] }) }
        format.html { redirect_back fallback_location: chatouille_path, alert: result[:error] }
      end
    end
  end

  # Collecter les revenus (appelé par le MJ ou automatiquement)
  def collect_income
    income = calculate_income
    @chatouille_state.increment!(:religion_credits, income[:credits])
    @chatouille_state.increment!(:faith_points, income[:faith])
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chatouille_accounting_path, notice: "Revenus collectés : #{income[:credits]} crédits, #{income[:faith]} foi" }
    end
  end

  # MJ: Déclencher un événement aléatoire
  def trigger_event
    user = User.find(params[:user_id])
    state = user.chatouille_state
    
    unless state
      redirect_to mj_dashboard_path, alert: "Ce joueur n'a pas de religion Chatouille."
      return
    end
    
    event = state.pick_random_event
    
    if event
      # Envoyer une holonews au joueur
      Holonew.create!(
        sender: current_user,
        title: "🪶 Kessar souhaite vous parler",
        content: "Ô grande Entité Chatouilleuse ! Votre humble prophète requiert une audience divine. Un événement important nécessite votre sagesse cosmique !",
        target_user: user.id,
        sender_alias: "Kessar le Prophète"
      )
      
      redirect_to mj_dashboard_path, notice: "Événement '#{event['title']}' déclenché pour #{user.username}."
    else
      redirect_to mj_dashboard_path, alert: "Plus d'événements disponibles pour l'étape actuelle."
    end
  end

  private

  def authorize_chatouille_access!
    unless current_user.chatouille_enabled?
      redirect_to root_path, alert: "Vous n'avez pas accès à ce mini-jeu."
    end
  end

  def set_chatouille_state
    @chatouille_state = current_user.chatouille_state || current_user.create_chatouille_state!
  end

  def authorize_mj!
    unless current_user.group&.name == "MJ"
      redirect_to root_path, alert: "Accès réservé au MJ."
    end
  end

  def find_action(action_type, action_id)
    actions = case action_type
              when "doctrine"
                doctrine_actions
              when "build"
                build_actions
              when "marketing"
                marketing_actions
              when "politics"
                politics_actions
              else
                []
              end
    
    actions.find { |a| a[:id] == action_id }
  end

  def doctrine_actions
    [
      { id: "pray", name: "Prière collective", cost: { faith: 0 }, effect: { faith: 2 } },
      { id: "sermon", name: "Sermon de Kessar", cost: { faith: 1 }, effect: { market_share: 0.2, converts: 3 } },
      { id: "meditation", name: "Méditation chatouilleuse", cost: { faith: 2 }, effect: { faith: 5 } }
    ]
  end

  def build_actions
    [
      { id: "small_temple", cost: { credits: 5000, missionaries: 1 }, effect: { temples: 1, market_share: 0.5 } },
      { id: "medium_temple", cost: { credits: 15000, missionaries: 2 }, effect: { temples: 1, market_share: 1.5, influence: 3 } },
      { id: "grand_temple", cost: { credits: 40000, missionaries: 3 }, effect: { temples: 1, market_share: 3.0, influence: 8 } },
      { id: "training_center", cost: { credits: 8000 }, effect: { missionaries: 2 } },
      { id: "propaganda_office", cost: { credits: 3000 }, effect: { market_share: 0.8 } }
    ]
  end

  def marketing_actions
    [
      { id: "flyers", cost: { credits: 100 }, effect: { market_share: 0.3, converts: 5 } },
      { id: "event", cost: { credits: 500, faith: 3 }, effect: { market_share: 0.8, converts: 15 } },
      { id: "holopromo", cost: { credits: 2000 }, effect: { market_share: 1.2, converts: 25 } },
      { id: "celebrity", cost: { credits: 10000, faith: 5 }, effect: { market_share: 2.0, converts: 40, influence: 5 } },
      { id: "galactic_campaign", cost: { credits: 50000, missionaries: 2 }, effect: { market_share: 4.0, converts: 100 } }
    ]
  end

  def politics_actions
    [
      { id: "lobby", cost: { credits: 1000 }, effect: { influence: 3 } },
      { id: "petition", cost: { faith: 5 }, effect: { influence: 5, market_share: 0.3 } },
      { id: "alliance", cost: { credits: 3000, faith: 3 }, effect: { influence: 8 } },
      { id: "council_speech", cost: { faith: 10 }, effect: { influence: 12, market_share: 0.5 } },
      { id: "political_maneuver", cost: { credits: 8000, faith: 8 }, effect: { influence: 20 } }
    ]
  end

  def execute_action(action)
    cost = action[:cost] || {}
    effect = action[:effect] || {}
    
    # Vérifier les ressources
    if cost[:faith] && @chatouille_state.faith_points < cost[:faith]
      return { success: false, error: "Pas assez de points de foi (#{@chatouille_state.faith_points}/#{cost[:faith]})" }
    end
    if cost[:credits] && @chatouille_state.religion_credits < cost[:credits]
      return { success: false, error: "Pas assez de crédits (#{@chatouille_state.religion_credits}/#{cost[:credits]})" }
    end
    if cost[:missionaries] && @chatouille_state.missionaries < cost[:missionaries]
      return { success: false, error: "Pas assez de missionnaires (#{@chatouille_state.missionaries}/#{cost[:missionaries]})" }
    end
    
    # Déduire les coûts
    @chatouille_state.faith_points -= cost[:faith] || 0
    @chatouille_state.religion_credits -= cost[:credits] || 0
    @chatouille_state.missionaries -= cost[:missionaries] || 0
    
    # Appliquer les effets
    @chatouille_state.faith_points += effect[:faith] || 0
    @chatouille_state.market_share += effect[:market_share] || 0
    @chatouille_state.political_influence += effect[:influence] || 0
    @chatouille_state.total_converts += effect[:converts] || 0
    @chatouille_state.temples_count += effect[:temples] || 0
    @chatouille_state.missionaries += effect[:missionaries] || 0
    
    # S'assurer des limites
    @chatouille_state.market_share = [[@chatouille_state.market_share, 0].max, 100].min
    @chatouille_state.political_influence = [[@chatouille_state.political_influence, 0].max, 100].min
    
    @chatouille_state.save!
    @chatouille_state.check_step_progression
    
    { success: true, action: action, cost: cost, effect: effect }
  end

  def calculate_income
    {
      credits: (@chatouille_state.total_converts * 0.1).round + 
               (@chatouille_state.temples_count * 5) + 
               (@chatouille_state.market_share * 2).round,
      faith: (@chatouille_state.temples_count * 2) + 
             (@chatouille_state.missionaries * 1)
    }
  end

  def turbo_stream_updates(result)
    turbo_stream.replace_all([
      turbo_stream.replace("resources-panel", partial: "chatouille/resources_panel"),
      turbo_stream.replace("market-chart", partial: "chatouille/market_chart"),
      turbo_stream.replace("action-result", partial: "chatouille/action_success", locals: { result: result })
    ])
  end
end

