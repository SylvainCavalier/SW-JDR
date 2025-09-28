class PazaakGame < ApplicationRecord
  belongs_to :host, class_name: "User"
  belongs_to :guest, class_name: "User", optional: true

  enum status: { waiting: 0, in_progress: 1, finished: 2 }

  serialize :host_state, JSON
  serialize :guest_state, JSON

  validates :host, presence: true
  validate :guest_not_host

  # Pas de broadcast automatique ici: les contrôleurs diffusent vers des streams personnalisés par joueur

  def stream_key
    "pazaak_game_#{id}"
  end

  def overlay_target
    "#{stream_key}_overlay"
  end

  def guest_not_host
    return if guest_id.nil?
    errors.add(:guest_id, "ne peut pas être l’hôte") if guest_id == host_id
  end

  def player_state(user)
    user.id == host_id ? host_state : guest_state
  end

  def opponent_state(user)
    user.id == host_id ? guest_state : host_state
  end

  def set_player_state!(user, state)
    if user.id == host_id
      update!(host_state: state)
    else
      update!(guest_state: state)
    end
  end

  def both_served?
    host_state["served"] && guest_state["served"]
  end

  def busted?(user)
    player_state(user)["bust"]
  end

  # --- Gameplay ---
  def start_game!
    init_player_state!(host)
    init_player_state!(guest)
    fp = [host_id, guest_id].compact.sample
    update!(status: :in_progress, round_number: 1, current_turn_user_id: fp, first_player_id: fp, started_at: Time.current)
    draw_main_card_for!(User.find(fp))
  end

  def default_player_state
    {
      "hand" => [],
      "hand_used" => [],
      "draws" => [],
      "played_specials" => [],
      "sum" => 0,
      "served" => false,
      "bust" => false
    }
  end

  def ensure_states!
    # Garantit que les deux états joueurs sont bien initialisés
    hs = (host_state.is_a?(Hash) ? host_state : {})
    gs = (guest_state.is_a?(Hash) ? guest_state : {})

    normalized_hs = default_player_state.merge(hs)
    normalized_gs = default_player_state.merge(gs)

    if normalized_hs != host_state || normalized_gs != guest_state
      update!(host_state: normalized_hs, guest_state: normalized_gs)
    end
  end

  def init_player_state!(user)
    specials = deck_for(user)
    state = {
      "hand" => specials.sample(4),
      "hand_used" => [],
      "draws" => [],
      "played_specials" => [],
      "sum" => 0,
      "served" => false,
      "bust" => false
    }
    set_player_state!(user, state)
  end

  def deck_for(user)
    # prefers custom deck (array of names), else default +/-1..5 names
    arr = Array(user&.pazaak_deck).map(&:to_s)
    return arr if arr.present?
    ((-5..-1).to_a + (1..5).to_a).map { |n| n.positive? ? "+#{n}" : n.to_s }
  end

  def reset_round_state!(user)
    state = (player_state(user) || {}).deep_dup
    state["draws"] = []
    state["played_specials"] = []
    state["sum"] = 0
    state["served"] = false
    state["bust"] = false
    state["round_banner"] = false
    set_player_state!(user, state)
  end

  def draw_main_card_for!(user)
    drawn = rand(1..10)
    state = (player_state(user) || {}).deep_dup
    state["sum"] += drawn
    state["bust"] = state["sum"] > 20
    # Auto-stand si pile 20
    state["served"] = true if state["sum"] == 20
    (state["draws"] ||= []) << drawn
    set_player_state!(user, state)
    update!(last_drawn_card: drawn)
  end

  def play_special_card!(user, value)
    state = (player_state(user) || {}).deep_dup
    name = value.to_s
    # Autoriser le jeu d'une carte spéciale même si bust, sauf si déjà servi
    return unless state["hand"].map(&:to_s).include?(name) && !state["served"]
    # Retirer de la main
    idx = state["hand"].map(&:to_s).index(name)
    state["hand"].delete_at(idx)
    state["hand_used"] << name
    # Persister immédiatement la main modifiée avant d'appliquer des effets proc
    set_player_state!(user, state)

    delta, proc = Pazaak::CardEffect.for(name)
    if proc
      proc.call(self, user)
    else
      state["sum"] += delta
      (state["played_specials"] ||= []) << delta
      state["bust"] = state["sum"] > 20
      # Auto-stand si pile 20
      state["served"] = true if state["sum"] == 20
      set_player_state!(user, state)
    end
  end

  def pass_turn!(_user)
    # Passer ne termine pas la manche; on avance simplement le tour.
    advance_turn!
  end

  def stand!(user)
    state = (player_state(user) || {}).deep_dup
    state["served"] = true
    set_player_state!(user, state)
    check_round_end!
  end

  def check_round_end!
    # Ne pas conclure immédiatement sur un bust si c'est encore le tour du joueur bust:
    # il peut jouer une carte spéciale négative pour revenir <= 20.
    # On ne conclut sur bust que si les deux sont servis ou si l'adversaire vient de terminer son tour.

    if both_served?
      compare_scores_and_finish!
      return
    end

    # Si le joueur courant est bust et ne peut plus jouer de carte (main vide), alors fin immédiate
    current_user = (current_turn_user_id == host_id) ? host : guest
    current_state = player_state(current_user)
    if current_state["bust"] && (current_state["hand"] || []).empty?
      winner = current_user.id == host_id ? guest : host
      register_round_win!(winner)
      return
    end

    advance_turn!
  end

  def compare_scores_and_finish!
    host_diff = 20 - host_state["sum"]
    guest_diff = 20 - guest_state["sum"]
    if host_diff < 0 && guest_diff < 0
      # double bust: égalité (aucun point)
      announce_round_winner!(nil)
      # stats: égalité de manche
      (host.pazaak_stat || host.build_pazaak_stat).record_round_tie!(opponent_id: guest_id)
      (guest.pazaak_stat || guest.build_pazaak_stat).record_round_tie!(opponent_id: host_id)
      NextRoundPazaakJob.set(wait: 3.seconds).perform_later(id)
      return
    end
    if host_diff == guest_diff
      # égalité
      announce_round_winner!(nil)
      (host.pazaak_stat || host.build_pazaak_stat).record_round_tie!(opponent_id: guest_id)
      (guest.pazaak_stat || guest.build_pazaak_stat).record_round_tie!(opponent_id: host_id)
      NextRoundPazaakJob.set(wait: 3.seconds).perform_later(id)
      return
    end
    winner = if host_diff < 0
      guest
    elsif guest_diff < 0
      host
    else
      host_diff < guest_diff ? host : guest
    end
    register_round_win!(winner)
  end

  def register_round_win!(winner_user)
    set_round_banner!(winner_user)
    if winner_user.id == host_id
      increment!(:wins_host)
    else
      increment!(:wins_guest)
    end
    # stats de manche
    loser_user = (winner_user.id == host_id ? guest : host)
    (winner_user.pazaak_stat || winner_user.build_pazaak_stat).record_round_win!(opponent_id: loser_user.id)
    (loser_user.pazaak_stat || loser_user.build_pazaak_stat).record_round_loss!(opponent_id: winner_user.id)
    if wins_host >= 3 || wins_guest >= 3
      update!(status: :finished, finished_at: Time.current)
      # Capturer la mise avant toute modification des invitations
      stake = (PazaakInvitation.find_by(pazaak_game_id: id)&.stake || 0).to_i
      apply_stake_transfer!(loser: (winner_user.id == host_id ? guest : host))
      # Détacher immédiatement les invitations pour éviter toute réutilisation avant destruction
      PazaakInvitation.where(pazaak_game_id: id).update_all(pazaak_game_id: nil)
      # Statistiques de fin de partie (victoire/défaite)
      winner_stat = winner_user.pazaak_stat || winner_user.build_pazaak_stat
      loser_user = (winner_user.id == host_id ? guest : host)
      loser_stat = loser_user.pazaak_stat || loser_user.build_pazaak_stat
      winner_stat.record_game!(won: true, stake: stake, opponent_id: loser_user.id, credits_delta: stake)
      loser_stat.record_game!(won: false, stake: stake, opponent_id: winner_user.id, credits_delta: -stake)
      # Afficher le vainqueur de PARTIE pendant 3s (overlay avec redirection)
      [host_id, guest_id].compact.each do |recipient_id|
        Turbo::StreamsChannel.broadcast_update_to(
          "user_#{recipient_id}",
          target: overlay_target,
          partial: "pazaak/games/winner",
          locals: { game: self, winner: winner_user, redirect_url: Rails.application.routes.url_helpers.pazaak_path, stake: stake }
        )
      end
      # Destruction après 3s (redirection gérée par l'overlay)
      FinishPazaakGameJob.set(wait: 3.seconds).perform_later(id)
    else
      # Afficher le vainqueur de manche (bandeau) puis démarrer la manche suivante via streams
      [host_id, guest_id].compact.each do |recipient_id|
        Turbo::StreamsChannel.broadcast_update_to(
          "user_#{recipient_id}",
          target: overlay_target,
          partial: "pazaak/games/winner",
          locals: { game: self, winner: winner_user, redirect_url: nil }
        )
      end
      # lancer la prochaine manche via stream après 3s
      NextRoundPazaakJob.set(wait: 3.seconds).perform_later(id)
    end
  end

  def announce_round_winner!(winner_user_or_nil)
    set_round_banner!(winner_user_or_nil)
    [host_id, guest_id].compact.each do |recipient_id|
      Turbo::StreamsChannel.broadcast_update_to(
        "user_#{recipient_id}",
        target: overlay_target,
        partial: "pazaak/games/winner",
        locals: { game: self, winner: winner_user_or_nil, redirect_url: nil }
      )
    end
  end

  def set_round_banner!(winner_user_or_nil)
    hs = (host_state || {}).deep_dup
    gs = (guest_state || {}).deep_dup
    hs["round_banner"] = true
    gs["round_banner"] = true
    update!(host_state: hs, guest_state: gs)
  end

  def round_banner?
    (host_state && host_state["round_banner"]) || (guest_state && guest_state["round_banner"]) || false
  end

  def abandon!(by_user)
    return if finished?
    update!(status: :finished, finished_at: Time.current)
    # Optionnel: on pourrait enregistrer une victoire au vainqueur
    apply_stake_transfer!(loser: by_user)
    # Maj stats: le joueur qui abandonne est perdant
    loser = by_user
    winner = (loser.id == host_id) ? guest : host
    stake = (PazaakInvitation.find_by(pazaak_game_id: id)&.stake || 0).to_i
    (winner.pazaak_stat || winner.build_pazaak_stat).record_game!(won: true, stake: stake, opponent_id: loser.id, credits_delta: stake)
    (loser.pazaak_stat  || loser.build_pazaak_stat).record_game!(won: false, stake: stake, opponent_id: winner.id, credits_delta: -stake)
    (loser.pazaak_stat  || loser.build_pazaak_stat).record_abandon!
  end

  def next_round!
    # Alterner le premier joueur de la manche suivante
    next_first = (first_player_id == host_id) ? guest_id : host_id
    update!(round_number: round_number + 1, current_turn_user_id: next_first, first_player_id: next_first)
    reset_round_state!(host)
    reset_round_state!(guest)
    # Tirage auto pour le nouveau premier joueur
    draw_main_card_for!(User.find(next_first))
  end

  def advance_turn!
    first_next_id = (current_turn_user_id == host_id) ? guest_id : host_id
    update!(current_turn_user_id: first_next_id)
    next_user = User.find(first_next_id)
    next_state = player_state(next_user)

    if next_state["served"]
      # Si le joueur suivant est déjà servi, on saute son tour
      # Si les deux sont servis, on conclut, sinon on revient au joueur non servi
      if both_served?
        compare_scores_and_finish!
        return
      end
      second_next_id = (first_next_id == host_id) ? guest_id : host_id
      update!(current_turn_user_id: second_next_id)
      second_user = User.find(second_next_id)
      second_state = player_state(second_user)
      draw_main_card_for!(second_user) unless second_state["served"] || second_state["bust"]
      return
    end

    if next_state["bust"]
      # Joueur suivant arrive bust (cas limite) → fin de manche si l'autre est servi ou ne peut pas corriger
      check_round_end!
      return
    end

    # Cas normal: début de son tour → tirage auto
    draw_main_card_for!(next_user)
    # Si la carte amène exactement à 20 (auto-servi) ou bust, gérer immédiatement
    next_state_after = player_state(next_user)
    if next_state_after["served"] || next_state_after["bust"]
      if both_served?
        compare_scores_and_finish!
        return
      end
      second_next_id = (first_next_id == host_id) ? guest_id : host_id
      update!(current_turn_user_id: second_next_id)
      second_user = User.find(second_next_id)
      second_state = player_state(second_user)
      draw_main_card_for!(second_user) unless second_state["served"] || second_state["bust"]
    end
  end

  def apply_move!(user, action_type, value = nil)
    return unless in_progress? && current_turn_user_id == user.id
    # Si un bandeau de fin de manche est affiché, ignorer tout rendu/avancée (anti-remplacement précoce)
    return if round_banner?

    case action_type
    when "draw"
      draw_main_card_for!(user)
    when "play_special"
      play_special_card!(user, value)
      return
    when "pass"
      pass_turn!(user)
      return
    when "stand"
      stand!(user)
      return
    end

    check_round_end! unless finished?
  end
end

private

def apply_stake_transfer!(loser:)
  inv = PazaakInvitation.find_by(pazaak_game_id: id)
  return unless inv && inv.stake.to_i > 0
  winner = (loser.id == host_id) ? guest : host
  return unless winner
  stake = inv.stake.to_i
  loser.update!(credits: loser.credits.to_i - stake)
  winner.update!(credits: winner.credits.to_i + stake)
end


