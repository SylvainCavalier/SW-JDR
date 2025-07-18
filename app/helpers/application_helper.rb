module ApplicationHelper

  def equipment_slot_image_path(slot)
    "slots/#{slot.parameterize.underscore}.png"
  end

  def asset_exists?(path)
    Rails.application.assets_manifest.find_sources(path).present?
  rescue
    false
  end

  def back_link(default_path = root_path)
    path = session.delete(:return_to) || default_path
    link_to path, class: "btn btn-outline-secondary position-fixed", style: "top: 20px; left: 20px;" do
      content_tag(:i, "", class: "fa-solid fa-chevron-left me-2") + "Retour"
    end
  end

  def position_icon(position)
    case position
    when "Pilote", "Copilote"
      "fa-steering-wheel"
    when "Ingénieur radar"
      "fa-radar"
    when "Gabier"
      "fa-shield"
    when "Maître machine"
      "fa-wrench"
    when /Canonnier/
      "fa-crosshairs"
    when "Ingénieur radio"
      "fa-radio"
    when "Lieutenant de navigation"
      "fa-compass"
    when "Maître d'équipage"
      "fa-users-cog"
    when "Capitaine"
      "fa-crown"
    when "Second du capitaine"
      "fa-user-tie"
    else
      "fa-user"
    end
  end

  SKILL_ORDER = {
    "Savoir" => [
      "Nature", "Substances", "Médecine", "Langages", "Astrophysique", "Planètes", "Savoir Jedi", "Évaluation", "Illégalité"
    ],
    "Dextérité" => [
      "Arts martiaux", "Armes blanches", "Tir", "Sabre-laser", "Lancer", "Esquive", "Discrétion", "Habileté", "Vitesse"
    ],
    "Perception" => [
      "Observation", "Sang-Froid", "Intuition", "Imitation", "Psychologie", "Commandement", "Marchandage", "Persuasion", "Dressage"
    ],
    "Technique" => [
      "Réparation", "Ingénierie", "Sécurité", "Démolition", "Systèmes"
    ],
    "Vigueur" => [
      "Escalade", "Endurance", "Saut", "Survie", "Intimidation", "Natation"
    ],
    "Mécanique" => [
      "Pilotage", "Esquive spatiale", "Astrogation", "Tourelles", "Jetpack"
    ]
  }.freeze
end
