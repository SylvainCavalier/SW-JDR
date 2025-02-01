class PetsController < ApplicationController
  before_action :set_pet, only: %i[show edit update destroy perform_action]

  def index
    @humanoids = Pet.where(category: "humanoïde").where.not(status: Status.find_by(name: "Mort"))
    @animals = Pet.where(category: "animal").where.not(status: Status.find_by(name: "Mort"))
    @droids = Pet.where(category: "droïde").where.not(status: Status.find_by(name: "Mort"))
    @bio_armors = Pet.where(category: "bio-armure").where.not(status: Status.find_by(name: "Mort"))
  end

  def new
    @pet = Pet.new
  end

  def create
    @pet = Pet.new(pet_params)
    @pet.hp_current = @pet.hp_max # Initialise les HP actuels aux HP max
    if @pet.save
      update_pet_skills(@pet)
      redirect_to @pet, notice: "Familier créé avec succès."
    else
      flash.now[:alert] = "Erreur lors de la création du familier."
      render :new
    end
  end

  def show
    @pet = Pet.find(params[:id])
  end

  def edit
    @pet = Pet.find(params[:id])
    ["Résistance Corporelle", "Vitesse", "Précision", "Esquive"].each do |skill_name|
      skill = Skill.find_by(name: skill_name)
      @pet.pet_skills.find_or_initialize_by(skill: skill)
    end
  end

  def update
    if @pet.update(pet_params)
      update_pet_skills(@pet)
      redirect_to @pet, notice: "Familier mis à jour avec succès."
    else
      flash.now[:alert] = "Erreur lors de la mise à jour du familier."
      render :edit
    end
  end

  def destroy
    @pet = Pet.find(params[:id])
    @pet.destroy
    redirect_to pets_path, notice: "Le familier a été supprimé avec succès."
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
    pet = current_user.pet
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

  def graveyard
    @dead_humanoids = Pet.where(category: "humanoïde", status: Status.find_by(name: "Mort"))
    @dead_animals = Pet.where(category: "animal", status: Status.find_by(name: "Mort"))
    @dead_droids = Pet.where(category: "droïde", status: Status.find_by(name: "Mort"))
    @dead_bio_armors = Pet.where(category: "bio-armure", status: Status.find_by(name: "Mort"))
  end

  def heal
    @pet = Pet.find(params[:id])
  
    # Recherche d'un medipack dans l'inventaire de l'utilisateur
    medipack = current_user.user_inventory_objects.joins(:inventory_object)
                       .find_by(inventory_objects: { name: "Medipack" })
  
    # Vérification si l'utilisateur possède un medipack
    if medipack.nil? || medipack.quantity <= 0
      redirect_to pet_path(@pet), alert: "Vous n'avez plus de Medipack !" and return
    end
  
    # Vérification si le familier est déjà au maximum de ses PV
    if @pet.hp_current >= @pet.hp_max
      redirect_to pet_path(@pet), alert: "Il a déjà ses points de vie au maximum !" and return
    end
  
    # Calcul des points de soin et mise à jour des PV
    heal_points = calculate_heal_points(current_user, @pet)
    new_hp = [@pet.hp_current + heal_points, @pet.hp_max].min
    @pet.update!(hp_current: new_hp)
  
    # Mise à jour de la quantité de medipacks et augmentation de la loyauté
    medipack.decrement!(:quantity)
    @pet.loyalty_up
  
    redirect_to pet_path(@pet), notice: "Votre familier a été soigné de #{heal_points} PV !"
  end

  def perform_action
    @pet = Pet.find(params[:id])
    action = params[:action_type]
  
    if current_user.pet_action_points <= 0
      redirect_to pet_path(@pet), alert: "Vous n'avez plus de points d'action !" and return
    end
  
    message = case action
              when "feed"
                @pet.feed!
              when "cuddle"
                @pet.cuddle!
              when "play"
                @pet.play!
              when "scold"
                @pet.scold!
              when "train"
                @pet.train!
              when "oil"
                @pet.oil!
              when "wipe_memory"
                @pet.wipe_memory!
              when "upgrade"
                @pet.upgrade!
              when "compliment"
                @pet.compliment!
              when "chat"
                @pet.chat!
              when "hit"
                @pet.hit!
              when "heal"
                @pet.heal!(current_user)
              else
                redirect_to pet_path(@pet), alert: "Action inconnue." and return
              end
  
    current_user.decrement!(:pet_action_points)
    render_flash_and_redirect(message)
  end
  
  private
  
  def calculate_heal_points(user, pet)
    dice_roll = rand(1..6) * user.user_skills.find_by(skill: Skill.find_by(name: "Médecine")).mastery
    bonus = user.user_skills.find_by(skill: Skill.find_by(name: "Médecine")).bonus
    dice_roll + bonus
  end

  def set_pet
    @pet = Pet.find(params[:id])
  end

  def pet_params
    params.require(:pet).permit(
      :name, :race, :description, :category, :url_image, 
      :hp_max, :weapon_1, :damage_1, :damage_1_bonus, 
      :weapon_2, :damage_2, :damage_2_bonus, :image, :size, :weight
    )
  end

  def update_pet_skills(pet)
    # Compétences liées au familier
    skills = {
      "Résistance Corporelle" => { mastery: params[:pet][:res_corp_mastery], bonus: params[:pet][:res_corp_bonus] },
      "Vitesse" => { mastery: params[:pet][:speed_mastery], bonus: params[:pet][:speed_bonus] },
      "Précision" => { mastery: params[:pet][:accuracy_mastery], bonus: params[:pet][:accuracy_bonus] },
      "Esquive" => { mastery: params[:pet][:dodge_mastery], bonus: params[:pet][:dodge_bonus] }
    }

    skills.each do |skill_name, values|
      skill = Skill.find_or_create_by(name: skill_name)
      pet_skill = pet.pet_skills.find_or_initialize_by(skill: skill)
      pet_skill.update(mastery: values[:mastery].to_i, bonus: values[:bonus].to_i)
    end
  end

  def render_flash_and_redirect(message)
    flash[:notice] = message
    redirect_to pet_path(@pet)
  end
end