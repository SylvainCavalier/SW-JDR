class PetsController < ApplicationController
  before_action :set_pet, only: %i[show edit update destroy perform_action]

  def index
    dead_status = Status.find_by(name: "Mort")
  
    # Récupère l'identifiant du pet associé au current_user, s'il existe
    user_pet_id = current_user.pet_id
  
    # Si un pet associé est trouvé, on le récupère
    @associated_pet = Pet.joins(:pet_statuses)
                         .where.not(pet_statuses: { status_id: dead_status.id })
                         .where(id: user_pet_id)
  
    @humanoids = Pet.joins(:pet_statuses)
                .where(category: "humanoïde")
                .where.not(pet_statuses: { status_id: dead_status.id })
                .yield_self { |q| user_pet_id.present? ? q.where.not(id: user_pet_id) : q }
                .order(:name)
    @animals   = Pet.joins(:pet_statuses).where(category: "animal").where.not(pet_statuses: { status_id: dead_status.id }).yield_self { |q| user_pet_id.present? ? q.where.not(id: user_pet_id) : q }.order(:name)
    @droids    = Pet.joins(:pet_statuses).where(category: "droïde").where.not(pet_statuses: { status_id: dead_status.id }).yield_self { |q| user_pet_id.present? ? q.where.not(id: user_pet_id) : q }.order(:name)
  end
  
  def graveyard
    dead_status = Status.find_by(name: "Mort")
  
    @dead_humanoids   = Pet.joins(:pet_statuses).where(category: "humanoïde", pet_statuses: { status_id: dead_status.id }).order(:name)
    @dead_animals     = Pet.joins(:pet_statuses).where(category: "animal", pet_statuses: { status_id: dead_status.id }).order(:name)
    @dead_droids      = Pet.joins(:pet_statuses).where(category: "droïde", pet_statuses: { status_id: dead_status.id }).order(:name)
    @dead_bio_armors  = Pet.joins(:pet_statuses).where(category: "bio-armure", pet_statuses: { status_id: dead_status.id }).order(:name)
  end

  def new
    @pet = Pet.new
  end

  def create
    @pet = Pet.new(pet_params)
    @pet.hp_current = @pet.hp_max
    if @pet.save
      update_pet_skills(@pet)
      redirect_to @pet, notice: "Familier créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @pet = Pet.find(params[:id])
    # Stocker la page d'origine seulement si on vient d'une autre page
    if request.referer.present? && !request.referer.include?(pet_path(@pet))
      session[:return_to] = request.referer
    end
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
  
    if pet.user.present?
      redirect_to pet_path(pet), notice: "#{pet.name} est déjà associé à un autre joueur. Il doit d'abord être dissocié."
    elsif current_user.update(pet_id: pet.id)
      redirect_to pet_path(pet), notice: "#{pet.name} a été associé à votre personnage."
    else
      redirect_to pet_path(pet), notice: "Impossible d'associer ce familier."
    end
  end
  
  def dissociate
    pet = current_user.pet
    if current_user.update(pet_id: nil)
      redirect_to pets_path, notice: "Le familier a été dissocié avec succès."
    else
      redirect_to pet_path(current_user.pet), notice: "Impossible de dissocier ce familier."
    end
  end

  def manage_pet
    if current_user.pet_id.present?
      redirect_to pet_path(current_user.pet_id)
    else
      redirect_to pets_path
    end
  end

  def heal
    @pet = Pet.find(params[:id])
  
    # Vérifier si un item a été sélectionné
    item_id = params[:item_id]
    if item_id.blank?
      redirect_to pet_path(@pet), alert: "Veuillez sélectionner un objet de soin !" and return
    end
  
    # Trouver l'objet de soin dans l'inventaire du joueur
    heal_item = current_user.user_inventory_objects.find_by(inventory_object_id: item_id)
    inventory_object = heal_item&.inventory_object || InventoryObject.find_by(id: item_id)
  
    if inventory_object.nil?
      redirect_to pet_path(@pet), alert: "Objet de soin introuvable !" and return
    end
  
    # Vérifier si l'objet est utilisable et a une quantité suffisante
    if heal_item.nil? || heal_item.quantity <= 0
      redirect_to pet_path(@pet), alert: "Vous n'avez plus cet objet de soin !" and return
    end
  
    # Vérifier si le pet est déjà au max de ses PV
    if @pet.hp_current >= @pet.hp_max
      redirect_to pet_path(@pet), alert: "Ce familier a déjà tous ses PV !" and return
    end
  
    # Application des effets de l'objet de soin
    healed_points, new_status = inventory_object.apply_effects(@pet, current_user)
    new_hp = [@pet.hp_current + healed_points, @pet.hp_max].min
  
    # Transaction pour appliquer les soins et mettre à jour l'inventaire
    ActiveRecord::Base.transaction do
      heal_item.decrement!(:quantity) if healed_points > 0
      @pet.update!(hp_current: new_hp)
  
      # Mise à jour du statut du pet si nécessaire
      if new_status
        @pet.set_status(new_status)
      end
    end
  
    redirect_to pet_path(@pet), notice: "Votre familier a été soigné de #{healed_points} PV avec #{inventory_object.name} !"
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

  def recharger_bouclier
    pet = Pet.find(params[:id])
  
    if pet.shield_max == 0
      return render json: { success: false, message: "Ce pet n'a pas de bouclier." }, status: :unprocessable_entity
    end
  
    cost = (pet.shield_max - pet.shield_current) * 10
  
    if current_user.credits < cost
      return render json: { success: false, message: "Pas assez de crédits pour recharger." }, status: :unprocessable_entity
    end
  
    current_user.update!(credits: current_user.credits - cost)
    pet.update!(shield_current: pet.shield_max)
  
    render json: { success: true, shield_current: pet.shield_max, message: "Bouclier rechargé !" }
  end
  
  private
  
  def calculate_heal_points(user, pet)
    skill = user.user_skills.find_by(skill: Skill.find_by(name: "Médecine"))
    return 0 unless skill

    dice_roll = Array.new(skill.mastery) { rand(1..6) }.sum
    total = dice_roll + skill.bonus
    (total.to_f / 2).ceil
  end

  def set_pet
    @pet = Pet.find(params[:id])
  end

  def pet_params
    params.require(:pet).permit(
      :name, :race, :age, :description, :category, :url_image, 
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