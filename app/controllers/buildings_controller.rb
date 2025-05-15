class BuildingsController < ApplicationController
  before_action :set_headquarter
  before_action :set_building, except: [:assign_pet]

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

  def assign_pet
    pet = Pet.find_by(id: params[:pet_id])
  
    if pet.nil?
      redirect_to buildings_headquarter_path, alert: "Aucun pet sélectionné."
      return
    end
  
    # 🔍 Vérifier et récupérer le bâtiment cible
    @building = Building.find_by(id: params[:id])
    unless @building
      redirect_to buildings_headquarter_path, alert: "Bâtiment introuvable."
      return
    end
  
    # Capacité max du dortoir
    dortoir = @headquarter.buildings
                          .where(category: "Dortoirs")
                          .order(level: :desc)
                          .first
    max_staff = dortoir ? dortoir.level * 10 : 0
  
    # Nombre actuel de pets assignés à un bâtiment du headquarter
    total_assigned_pets = BuildingPet.joins(:building)
                                     .where(buildings: { headquarter_id: @headquarter.id })
                                     .count
  
    Rails.logger.debug "🔍 Dortoir trouvé: #{dortoir.inspect}"
    Rails.logger.debug "🏗️ Level du dortoir : #{dortoir&.level}"
    Rails.logger.debug "🔍 Capacité max : #{max_staff}"
    Rails.logger.debug "🔍 Nombre actuel de pets assignés : #{total_assigned_pets}"
  
    if total_assigned_pets >= max_staff
      redirect_to buildings_headquarter_path, alert: "Capacité maximale de personnel atteinte ! (#{max_staff} places max)"
      return
    end
  
    # Vérifier si le pet est déjà assigné à un autre bâtiment
    if BuildingPet.exists?(pet_id: pet.id)
      redirect_to buildings_headquarter_path, alert: "#{pet.name} est déjà assigné à un autre bâtiment."
      return
    end
  
    # ✅ Création sécurisée de la relation
    begin
      BuildingPet.create!(building: @building, pet: pet)
      Rails.logger.debug "✅ #{pet.name} a bien été assigné au bâtiment #{@building.name}"
      redirect_to buildings_headquarter_path, notice: "#{pet.name} a été assigné au bâtiment."
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "❌ Erreur lors de l'assignation : #{e.message}"
      redirect_to buildings_headquarter_path, alert: "Erreur lors de l'assignation du personnel."
    end
  end

  def remove_pet
    pet = @building.pets.find_by(id: params[:pet_id])
  
    if pet.nil?
      redirect_to buildings_headquarter_path, alert: "Ce pet n'est pas assigné à ce bâtiment."
      return
    end
  
    # Vérifie si le pet est chef du bâtiment
    if @building.chief_pet_id == pet.id
      @building.update!(chief_pet_id: nil)
    end
  
    # Retirer le pet du bâtiment
    @building.pets.delete(pet)
  
    redirect_to buildings_headquarter_path, notice: "#{pet.name} a été retiré du bâtiment."
  end

  def set_chief_pet
    pet = @building.pets.find_by(id: params[:chief_pet_id])
  
    if pet.nil?
      redirect_to buildings_headquarter_path, alert: "Le pet sélectionné n'est pas assigné à ce bâtiment."
      return
    end
  
    @building.update!(chief_pet_id: pet.id)
  
    redirect_to buildings_headquarter_path, notice: "#{pet.name} est maintenant le chef du bâtiment."
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