class PazaakLobbyChannel < ApplicationCable::Channel
  def subscribed
    stream_for "pazaak_lobby"
    if current_user
      PazaakPresence.touch!(current_user)
      broadcast_presence
    end
  end

  def unsubscribed
    # On ne supprime pas immédiatement ; le recent scope expirera
    broadcast_presence
  end

  def ping
    PazaakPresence.touch!(current_user)
    broadcast_presence
  end

  private

  def broadcast_presence
    players = PazaakPresence.recent.includes(:user).map(&:user)
    players.each do |recipient|
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{recipient.id}",
        target: "pazaak_lobby_players",
        partial: "pazaak/lobbies/players",
        locals: { players: players, self_id: recipient.id }
      )
    end
  end
end


