module Pazaak
  class LobbiesController < ApplicationController
    before_action :authenticate_user!

    def index
      PazaakPresence.touch!(current_user)
      @players = PazaakPresence.recent.includes(:user).map(&:user)
    end

    def ping
      PazaakPresence.touch!(current_user)
      players = PazaakPresence.recent.includes(:user).map(&:user)
      players.each do |recipient|
        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{recipient.id}",
          target: "pazaak_lobby_players",
          partial: "pazaak/lobbies/players",
          locals: { players: players, self_id: recipient.id }
        )
      end
      head :ok
    end
  end
end


