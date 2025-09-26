class DestroyPazaakGameJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = PazaakGame.find_by(id: game_id)
    return unless game
    # Détacher l'invitation liée si besoin pour éviter la violation de FK
    PazaakInvitation.where(pazaak_game_id: game.id).update_all(pazaak_game_id: nil)
    game.destroy
    # Optionnel: nettoyer les frames des joueurs (redirigés via redirect_controller)
  end
end


