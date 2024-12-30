class InventoryObject < ApplicationRecord
  has_many :user_inventory_objects
  has_many :users, through: :user_inventory_objects
  validates :name, presence: true, uniqueness: true

  def apply_effects(user, healer)
    heal_points = 0
    new_status = user.current_status&.name
  
    if user.hp_current <= -10 && name != "Trompe-la-mort"
      Rails.logger.info "❌ Les objets de soins ne peuvent pas être utilisés sur un joueur mort : #{user.username}."
      return [0, nil]
    end
  
    case name

    when "Homéopathie"
      if user.hp_max - user.hp_current <= 5
        heal_points = user.hp_max - user.hp_current
      else
        Rails.logger.info "❌ Homéopathie ne peut être utilisée sur #{user.username} car ses PV manquants sont > 5."
        heal_points = 0
      end

    when "Medipack"
      heal_points = (healer.medicine_roll / 2.0).ceil
  
    when "Medipack +"
      heal_points = (healer.medicine_roll / 2.0).ceil + rand(1..6)
  
    when "Medipack Deluxe"
      heal_points = healer.medicine_roll
  
    when "Antidote"
      if new_status == "Empoisonné"
        new_status = "En forme" # Rétablit le statut par défaut
        heal_points = rand(1..6) # Ajoute 1D
        Rails.logger.info "✔️ Antidote utilisé, statut 'Empoisonné' guéri pour #{user.username}."
      else
        Rails.logger.info "⚠️ Antidote sans effet sur #{user.username}, statut actuel : #{new_status || 'Aucun'}."
      end
  
    when "Extrait de Nysillin"
      heal_points = 2.times.map { rand(1..6) }.sum
  
    when "Baume de Kolto"
      heal_points = 4.times.map { rand(1..6) }.sum
  
    when "Sérum de Thyffera"
      if ["Malade", "Gravement Malade"].include?(new_status)
        if new_status == "Gravement Malade" && healer.classe_perso&.name != "Bio-savant"
          Rails.logger.info "❌ Sérum de Thyffera inefficace sur #{user.username} (#{new_status}) sans Bio-savant comme soigneur."
          return [0, nil] # Aucune guérison, aucun changement de statut
        else
          new_status = "En forme" # Rétablit le statut par défaut
          heal_points = rand(1..6) # Ajoute 1D
          Rails.logger.info "✔️ Sérum de Thyffera utilisé, statut '#{new_status}' guéri pour #{user.username}."
        end
      else
        Rails.logger.info "⚠️ Sérum de Thyffera sans effet sur #{user.username}, statut actuel : #{new_status || 'Aucun'}."
        return [0, nil] # Aucune guérison, aucun changement de statut
      end
  
    when "Rétroviral kallidahin"
      if new_status == "Maladie Virale"
        new_status = "En forme" # Rétablit le statut par défaut
        heal_points = rand(1..6) # Ajoute 1D
        Rails.logger.info "✔️ Rétroviral kallidahin utilisé, statut 'Maladie Virale' guéri pour #{user.username}."
      else
        Rails.logger.info "⚠️ Rétroviral kallidahin sans effet sur #{user.username}, statut actuel : #{new_status || 'Aucun'}."
      end
  
    when "Draineur de radiations"
      if new_status == "Irradié"
        new_status = "En forme" # Rétablit le statut par défaut
        heal_points = rand(1..6) # Ajoute 1D
        Rails.logger.info "✔️ Draineur de radiations utilisé, statut 'Irradié' guéri pour #{user.username}."
      else
        Rails.logger.info "⚠️ Draineur de radiations sans effet sur #{user.username}, statut actuel : #{new_status || 'Aucun'}."
      end
  
    when "Trompe-la-mort"
      if user.hp_current <= -10 && user.hp_current > -20
        heal_points = 2.times.map { rand(1..6) }.sum
        Rails.logger.info "✔️ Trompe-la-mort utilisé pour ressusciter #{user.username}."
      else
        Rails.logger.info "⚠️ Trompe-la-mort non applicable sur #{user.username} (HP actuels : #{user.hp_current})."
      end
  
    else
      Rails.logger.debug "⚠️ Objet #{name} non reconnu pour un effet spécifique."
    end
  
    [heal_points, new_status == user.current_status&.name ? nil : new_status]
  end
end