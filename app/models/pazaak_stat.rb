class PazaakStat < ApplicationRecord
  belongs_to :user

  # won: a gagné la PARTIE ?
  # stake: mise de la partie
  # credits_delta: +stake pour le gagnant, -stake pour le perdant (transfert net)
  def record_game!(won:, stake:, opponent_id:, credits_delta: 0)
    self.games_played += 1
    if won
      self.games_won += 1
      self.current_win_streak += 1
      self.best_win_streak = [best_win_streak, current_win_streak].max
      self.current_lose_streak = 0
    else
      self.games_lost += 1
      self.current_lose_streak += 1
      self.worst_lose_streak = [worst_lose_streak, current_lose_streak].max
      self.current_win_streak = 0
    end

    # Comptes de crédits: séparer total misé, gagné, perdu
    # total misé = somme des stakes joués
    self.stake_sum += stake
    self.stake_count += 1
    self.stake_max = [stake, stake_max].max
    self.stake_min = (stake_min.zero? ? stake : [stake_min, stake].min)

    # gagnés/perdus = flux nets
    self.credits_won += [credits_delta, 0].max
    self.credits_lost += [-credits_delta, 0].max

    counters = (opponent_counters || {})
    c = counters[opponent_id.to_s] || { "played" => 0, "won" => 0, "lost" => 0 }
    c["played"] += 1
    won ? c["won"] += 1 : c["lost"] += 1
    counters[opponent_id.to_s] = c
    self.opponent_counters = counters

    # compute playmate/nemesis/victim
    max_played = counters.max_by { |_k, v| v["played"] }
    self.playmate_user_id = max_played&.first&.to_i
    max_lost = counters.max_by { |_k, v| v["lost"] }
    self.nemesis_user_id = max_lost&.first&.to_i
    max_won = counters.max_by { |_k, v| v["won"] }
    self.victim_user_id = max_won&.first&.to_i

    save!
  end

  def record_round_win!(opponent_id:)
    self.rounds_won += 1
    bump_opponent_counter(opponent_id, won: true)
    save!
  end

  def record_round_loss!(opponent_id:)
    self.rounds_lost += 1
    bump_opponent_counter(opponent_id, won: false)
    save!
  end

  def record_round_tie!(opponent_id:)
    self.rounds_tied += 1
    counters = (opponent_counters || {})
    c = counters[opponent_id.to_s] || { "played" => 0, "won" => 0, "lost" => 0, "tied" => 0 }
    c["played"] += 1
    c["tied"] = (c["tied"] || 0) + 1
    counters[opponent_id.to_s] = c
    self.opponent_counters = counters
    save!
  end

  def record_abandon!
    self.games_abandoned += 1
    save!
  end

  def win_rate
    return 0.0 if games_played.zero?
    (games_won.to_f / games_played).round(3)
  end

  def stake_avg
    return 0 if stake_count.zero?
    (stake_sum.to_f / stake_count).round(2)
  end

  private

  def bump_opponent_counter(opponent_id, won:)
    counters = (opponent_counters || {})
    c = counters[opponent_id.to_s] || { "played" => 0, "won" => 0, "lost" => 0 }
    c["played"] += 1
    won ? c["won"] = c.fetch("won", 0) + 1 : c["lost"] = c.fetch("lost", 0) + 1
    counters[opponent_id.to_s] = c
    self.opponent_counters = counters
    max_played = counters.max_by { |_k, v| v["played"] }
    self.playmate_user_id = max_played&.first&.to_i
    max_lost = counters.max_by { |_k, v| v["lost"] }
    self.nemesis_user_id = max_lost&.first&.to_i
    max_won = counters.max_by { |_k, v| v["won"] }
    self.victim_user_id = max_won&.first&.to_i
  end
end


