module CombatBroadcaster
  extend ActiveSupport::Concern

  private

  # Diffuse la mise à jour d'une valeur (PV ou bouclier) d'un participant
  # vers l'assistant de combat (canal `combat_updates`).
  #
  # field accepte : "hp_current", "shield_current", "echani_shield_current".
  def broadcast_combat_assistant_update(participant, field)
    max = case field
          when "hp_current" then participant.hp_max
          when "echani_shield_current" then participant.echani_shield_max
          else participant.shield_max
          end

    Turbo::StreamsChannel.broadcast_replace_to(
      "combat_updates",
      target: "#{ActionView::RecordIdentifier.dom_id(participant)}_#{field == 'hp_current' ? 'hp' : 'shield'}_value",
      partial: "pages/combat_value",
      locals: {
        participant: participant,
        field: field,
        current: participant.send(field),
        max: max
      }
    )
  end
end
