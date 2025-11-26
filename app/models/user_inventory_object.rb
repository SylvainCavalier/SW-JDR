class UserInventoryObject < ApplicationRecord
  belongs_to :user
  belongs_to :inventory_object

  after_create :auto_unlock_drink

  private

  def auto_unlock_drink
    return unless inventory_object.category == 'drinks'
    return if inventory_object.catalog_id.blank?

    # Débloquer l'alcool pour le joueur s'il n'est pas déjà débloqué
    # Utilise catalog_id directement depuis l'inventory_object (plus besoin du YAML)
    discovered_drinks = user.discovered_drinks || []
    unless discovered_drinks.include?(inventory_object.catalog_id)
      discovered_drinks << inventory_object.catalog_id
      user.update!(discovered_drinks: discovered_drinks)
      Rails.logger.info "🍷 Alcool '#{inventory_object.name}' automatiquement débloqué pour #{user.username}"
    end
  end
end
