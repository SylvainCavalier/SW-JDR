class PetsController < ApplicationController
  before_action :set_pet, only: [:show, :edit, :update, :destroy]

  def index
    @pets = Pet.all
  end

  def new
    @pet = Pet.new
  end

  def create
    @pet = Pet.new(pet_params)
    if @pet.save
      redirect_to @pet, notice: 'Le familier a été créé avec succès.'
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @pet.update(pet_params)
      redirect_to @pet, notice: 'Les informations du familier ont été mises à jour.'
    else
      render :edit
    end
  end

  def destroy
    @pet.destroy
    redirect_to pets_path, notice: 'Le familier a été supprimé.'
  end

  def associate
    pet = Pet.find(params[:id])
    if current_user.update(pet_id: pet.id)
      redirect_to pet_path(pet), notice: "#{pet.name} a été associé à votre personnage."
    else
      redirect_to pet_path(pet), alert: "Impossible d'associer ce familier."
    end
  end
  
  def dissociate
    if current_user.update(pet_id: nil)
      redirect_to pets_path, notice: "Le familier a été dissocié avec succès."
    else
      redirect_to pet_path(current_user.pet), alert: "Impossible de dissocier ce familier."
    end
  end

  def manage_pet
    if current_user.pet_id.present?
      redirect_to pet_path(current_user.pet_id)
    else
      redirect_to pets_path
    end
  end

  private

  def set_pet
    @pet = Pet.find(params[:id])
  end

  def pet_params
    params.require(:pet).permit(:name, :race, :hp_current, :hp_max, :res_corp, :res_corp_bonus, :speed, :damage_1, :damage_2, :accuracy, :dodge, :weapon_1, :weapon_2)
  end
end