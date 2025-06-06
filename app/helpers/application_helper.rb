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
