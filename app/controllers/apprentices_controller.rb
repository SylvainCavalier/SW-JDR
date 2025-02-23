class ApprenticesController < ApplicationController
  before_action :set_apprentice, only: %i[show edit update destroy]

  def index
    @force_sensitive_pets = Pet.force_sensitive_humanoids
  end

  def show; end

  def new
    @apprentice = Apprentice.new
  end

  def create_from_pet
    pet = Pet.find(params[:pet_id])
  
    unless pet.category == "humanoïde" && pet.force?
      redirect_to pet_path(pet), alert: "Ce pet ne peut pas devenir apprenti."
      return
    end
  
    if current_user.apprentice.present?
      redirect_to pet_path(pet), alert: "Vous avez déjà un apprenti."
      return
    end
  
    apprentice = Apprentice.new(
      pet: pet,
      user: current_user,
      jedi_name: pet.name, # On garde le nom de base
      side: 0,
      speciality: "Commun",
      midi_chlorians: rand(5000..20000),
      saber_style: nil
    )
  
    if apprentice.save
      redirect_to apprentice_path(apprentice), notice: "Apprenti créé avec succès !"
    else
      redirect_to pet_path(pet), alert: "Une erreur est survenue lors de la création de l'apprenti."
    end
  end

  def edit; end

  def update
    if @apprentice.update(apprentice_params)
      redirect_to apprentice_path(@apprentice), notice: "Apprenti mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @apprentice.destroy
    redirect_to apprentices_path, notice: "Apprenti supprimé avec succès."
  end

  private

  def set_apprentice
    @apprentice = Apprentice.find(params[:id])
  end

  def apprentice_params
    params.require(:apprentice).permit(:name, :pet_id)
  end
end