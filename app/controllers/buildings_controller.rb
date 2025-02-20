class BuildingsController < ApplicationController
  before_action :set_headquarter
  before_action :set_building

  def upgrade
    next_level = @building.level + 1
    building_data = Building::BUILDING_DATA[@building.category][next_level.to_s]

    if building_data.nil?
      redirect_to buildings_headquarter_path, alert: "Amélioration impossible. Ce bâtiment est déjà au niveau maximum."
      return
    end

    if @headquarter.credits < building_data["price"]
      redirect_to buildings_headquarter_path, alert: "Crédits insuffisants pour améliorer ce bâtiment."
      return
    end

    ActiveRecord::Base.transaction do
      @headquarter.update!(credits: @headquarter.credits - building_data["price"])
      @building.update!(
        level: next_level,
        name: building_data["name"],
        description: building_data["description"],
        price: building_data["price"],
        properties: building_data["properties"]
      )
    end

    redirect_to buildings_headquarter_path, notice: "Le bâtiment #{@building.name} a été amélioré au niveau #{next_level} !"
  rescue => e
    redirect_to buildings_headquarter_path, alert: "Une erreur est survenue : #{e.message}"
  end

  private

  def set_headquarter
    @headquarter = Headquarter.first
  end

  def set_building
    @building = @headquarter.buildings.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to headquarter_buildings_path, alert: "Bâtiment introuvable."
  end
end