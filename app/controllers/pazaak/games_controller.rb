module Pazaak
  class GamesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_game

    def show
      @game.ensure_states!
    end

    def abandon
    quitter = current_user
    @game.abandon!(quitter)
    # Informer les deux joueurs puis détruire la partie après 3s
    [@game.host_id, @game.guest_id].compact.each do |recipient_id|
      Turbo::StreamsChannel.broadcast_update_to(
        "user_#{recipient_id}",
        target: @game.stream_key,
        partial: "pazaak/games/abandoned",
        locals: { quitter: quitter }
      )
    end
    DestroyPazaakGameJob.set(wait: 3.seconds).perform_later(@game.id)
    redirect_to root_path, notice: "Partie abandonnée."
    end

    private

    def set_game
      @game = PazaakGame.find(params[:id])
    end
  end
end


