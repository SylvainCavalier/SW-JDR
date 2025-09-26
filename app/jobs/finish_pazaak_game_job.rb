class FinishPazaakGameJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = PazaakGame.find_by(id: game_id)
    return unless game
    # Redirige les deux joueurs vers pazaak_path
    [game.host_id, game.guest_id].compact.each do |recipient_id|
      Turbo::StreamsChannel.broadcast_update_to(
        "user_#{recipient_id}",
        target: "pazaak_redirect",
        partial: "pazaak/redirect",
        locals: { url: Rails.application.routes.url_helpers.pazaak_path }
      )
    end
    # Détache l'invitation liée et détruit la partie
    PazaakInvitation.where(pazaak_game_id: game.id).update_all(pazaak_game_id: nil)
    game.destroy
  end
end


