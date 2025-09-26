module Pazaak
  class MovesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_game

    def create
      action_type = params[:action_type]
      value = params[:value]
      @game.apply_move!(current_user, action_type, value)
      # Recharger l'état et ne pas écraser le bandeau/fin de partie
      @game.reload
      if @game.round_banner? || @game.finished?
        head :ok and return
      end

      # Rendu pour le joueur courant
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            @game.stream_key,
            partial: "pazaak/games/game",
            locals: { game: @game, viewer: current_user }
          )
        end
        format.html { redirect_to pazaak_game_path(@game) }
      end

      # Diffusion aux deux joueurs (si pas de bandeau/fin)
      [@game.host_id, @game.guest_id].compact.each do |recipient_id|
        Turbo::StreamsChannel.broadcast_update_to(
          "user_#{recipient_id}",
          target: @game.stream_key,
          partial: "pazaak/games/game",
          locals: { game: @game, viewer: User.find(recipient_id) }
        )
      end
    end

    private

    def set_game
      @game = PazaakGame.find(params[:game_id])
    end
  end
end


