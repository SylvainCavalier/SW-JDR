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
end
