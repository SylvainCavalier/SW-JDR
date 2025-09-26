class NextRoundPazaakJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = PazaakGame.find_by(id: game_id)
    return unless game&.in_progress?
    game.next_round!
    # Diffuser l'état frais aux deux joueurs
    [game.host_id, game.guest_id].compact.each do |recipient_id|
      Turbo::StreamsChannel.broadcast_update_to(
        "user_#{recipient_id}",
        target: game.stream_key,
        partial: "pazaak/games/game",
        locals: { game: game, viewer: User.find(recipient_id) }
      )
    end
  end
end


