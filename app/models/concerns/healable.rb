module Healable
  extend ActiveSupport::Concern

  def apply_effects(target, healer)
    heal_points = 0
    new_status = target.current_status&.name

    # Vérifier si la cible est morte (ne peut être soignée que par Trompe-la-mort)
    if target.hp_current <= -10 && name != "Trompe-la-mort"
      Rails.logger.info "❌ Impossible d'utiliser cet objet sur #{target.name}, il est mort."
      return [0, nil]
    end

    case name
    when "Homéopathie"
      if target.hp_max - target.hp_current <= 5
        heal_points = target.hp_max - target.hp_current
      else
        Rails.logger.info "❌ Homéopathie ne peut être utilisée sur #{target.name} car ses PV manquants sont > 5."
      end

    when "Medipack"
      heal_points = (healer.medicine_roll / 2.0).ceil
  
    when "Medipack +"
      heal_points = (healer.medicine_roll / 2.0).ceil + rand(1..6)
  
    when "Medipack Deluxe"
      heal_points = healer.medicine_roll

    when "Antidote"
      if new_status == "Empoisonné"
        new_status = "En forme"
        heal_points = rand(1..6)
        Rails.logger.info "✔️ Antidote utilisé, statut 'Empoisonné' guéri pour #{target.name}."
      else
        Rails.logger.info "⚠️ Antidote sans effet sur #{target.name}."
      end

    when "Extrait de Nysillin"
      heal_points = 2.times.map { rand(1..6) }.sum

    when "Baume de Kolto"
      heal_points = 4.times.map { rand(1..6) }.sum

    when "Sérum de Thyffera"
      if ["Malade", "Gravement Malade"].include?(new_status)
        if new_status == "Gravement Malade" && healer.classe_perso&.name != "Bio-savant"
          Rails.logger.info "❌ Sérum de Thyffera inefficace sur #{target.name} sans Bio-savant."
          return [0, nil]
        else
          new_status = "En forme"
          heal_points = rand(1..6)
          Rails.logger.info "✔️ Sérum de Thyffera utilisé, statut guéri pour #{target.name}."
        end
      else
        Rails.logger.info "⚠️ Sérum de Thyffera sans effet sur #{target.name}."
      end

    when "Rétroviral kallidahin"
      if new_status == "Maladie Virale"
        new_status = "En forme"
        heal_points = rand(1..6)
        Rails.logger.info "✔️ Rétroviral kallidahin utilisé, statut 'Maladie Virale' guéri pour #{target.name}."
      else
        Rails.logger.info "⚠️ Rétroviral kallidahin sans effet sur #{target.name}."
      end

    when "Draineur de radiations"
      if new_status == "Irradié"
        new_status = "En forme"
        heal_points = rand(1..6)
        Rails.logger.info "✔️ Draineur de radiations utilisé, statut 'Irradié' guéri pour #{target.name}."
      else
        Rails.logger.info "⚠️ Draineur de radiations sans effet sur #{target.name}."
      end

    when "Trompe-la-mort"
      if target.hp_current <= -10 && target.hp_current > -20
        heal_points = 2.times.map { rand(1..6) }.sum
        Rails.logger.info "✔️ Trompe-la-mort utilisé pour ressusciter #{target.name}."
      else
        Rails.logger.info "⚠️ Trompe-la-mort non applicable sur #{target.name}."
      end

    else
      Rails.logger.debug "⚠️ Objet #{name} non reconnu pour un effet spécifique."
    end

    [heal_points, new_status == target.current_status&.name ? nil : new_status]
  end
end