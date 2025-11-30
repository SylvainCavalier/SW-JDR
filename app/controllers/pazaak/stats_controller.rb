module Pazaak
  class StatsController < ApplicationController
    before_action :authenticate_user!

    def show
      @stats = current_user.pazaak_stat || current_user.build_pazaak_stat

      # Récupérer les stats de tous les joueurs du groupe PJ pour les classements
      pj_group = Group.find_by(name: "PJ")
      @pj_stats = PazaakStat.joins(:user)
                            .where(users: { group_id: pj_group&.id })
                            .includes(:user)

      # Préparer les classements pour différentes catégories
      @rankings = {
        games_won: @pj_stats.order(games_won: :desc).to_a,
        win_rate: @pj_stats.select { |s| s.games_played > 0 }.sort_by { |s| -s.win_rate },
        credits_won: @pj_stats.order(credits_won: :desc).to_a,
        best_win_streak: @pj_stats.order(best_win_streak: :desc).to_a,
        rounds_won: @pj_stats.order(rounds_won: :desc).to_a,
        games_played: @pj_stats.order(games_played: :desc).to_a
      }
    end
  end
end


