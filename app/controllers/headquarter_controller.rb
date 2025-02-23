class HeadquarterController < ApplicationController
  before_action :set_headquarter

  def show
  end

  def edit
  end

  def observation
  end

  def update
    if @headquarter.update(headquarter_params)
      redirect_to headquarter_path, notice: "Base mise à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @headquarter = Headquarter.new
  end

  def create
    @headquarter = Headquarter.new(headquarter_params)
    if @headquarter.save
      redirect_to headquarter_path, notice: "Base créée"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def inventory
    @headquarter_objects = User.includes(:avatar_attachment) # Précharge les avatars
                               .index_with { |user| HeadquarterObject.where(user: user) }
                               .sort_by { |user, _| user == current_user ? 0 : 1 }
                               .to_h
  end

  def update_quantity
    item = HeadquarterObject.find(params[:id])
    change = params[:change].to_i
  
    if change == -1 && item.quantity <= 1
      item.destroy
      render json: { removed: true, item_id: item.id }
    else
      item.update(quantity: item.quantity + change)
      render json: { item_id: item.id, new_quantity: item.quantity }
    end
  end
  
  def add_item
    item_name = params[:name].strip
    quantity = params[:quantity].to_i
  
    if item_name.blank? || quantity <= 0
      render json: { error: "Nom invalide ou quantité insuffisante." }, status: :unprocessable_entity
      return
    end
  
    item = HeadquarterObject.find_or_initialize_by(name: item_name, user: current_user)

    if item.new_record?
      item.quantity = quantity
    else
      item.quantity += quantity
    end

    item.save!
  
    render json: { item_id: item.id, name: item.name, new_quantity: item.quantity, user_id: current_user.id }
  end
  
  def remove_item
    item = HeadquarterObject.find(params[:id])
    item.destroy
  
    render json: { removed: true, item_id: item.id }
  end

  def buildings
    @buildings = @headquarter.buildings.includes(:pets)
    @available_buildings = Building.all - @buildings
  end

  def personnel
    @personnel = @headquarter.pets
  end

  def shop
  end

  def credits
  end

  def transfer_credits
    receiver = User.find_by(username: params[:receiver_username])

    if receiver.nil?
      flash.now[:alert] = 'Destinataire introuvable'
      render :credits, status: :unprocessable_entity and return
    end

    amount = params[:amount].to_i

    if amount <= 0
      flash.now[:alert] = 'Le montant doit être supérieur à zéro.'
      render :credits, status: :unprocessable_entity and return
    end

    if @headquarter.credits < amount
      flash.now[:alert] = 'Crédits insuffisants dans la base.'
      render :credits, status: :unprocessable_entity and return
    end

    ActiveRecord::Base.transaction do
      @headquarter.update!(credits: @headquarter.credits - amount)
      receiver.update!(credits: receiver.credits + amount)
    end

    # Mise à jour dynamique des crédits
    receiver.broadcast_credits_update

    flash[:notice] = 'Transfert réussi.'
    redirect_to credits_headquarter_path
  rescue => e
    flash.now[:alert] = "Une erreur s'est produite : #{e.message}"
    render :credits, status: :internal_server_error
  end

  def personnel
    @headquarter = Headquarter.first # Unique HQ
  
    @personnel = Pet.joins(:building_pets)
                    .joins("INNER JOIN buildings ON buildings.id = building_pets.building_id")
                    .where("buildings.headquarter_id = ?", @headquarter.id)
                    .includes(building_pets: :building)
  
    @total_personnel = @personnel.count
  
    @dormitory = @headquarter.buildings
                         .where(category: "Dortoirs")
                         .order(level: :desc)
                         .first

    @capacity_max = @dormitory ? @dormitory.level * 10 : 0
  end

  def remove_personnel
    @building_pet = BuildingPet.find_by(pet_id: params[:id])
  
    if @building_pet
      @building_pet.destroy
  
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove("personnel_#{params[:id]}") }
        format.html { redirect_to personnel_headquarter_path, notice: "Membre supprimé avec succès." }
      end
    else
      respond_to do |format|
        format.html { redirect_to personnel_headquarter_path, alert: "Erreur : ce membre du personnel n'est pas affecté à un bâtiment." }
      end
    end
  end

  def defenses
    @headquarter = Headquarter.first
    @installed_defenses = @headquarter.defenses || []
    @available_defenses = Defense.where.not(id: @installed_defenses.pluck(:id)) || []
  end

  def buy_defense
    @headquarter = Headquarter.first
    defense = Defense.find(params[:id])
  
    if @headquarter.credits >= defense.price && !@headquarter.defenses.include?(defense)
      @headquarter.defenses << defense
      @headquarter.update(credits: @headquarter.credits - defense.price)
      redirect_to defenses_headquarter_path, notice: "Défense achetée avec succès !"
    else
      redirect_to defenses_headquarter_path, alert: "Achat impossible."
    end
  end

  private

  def headquarter_params
    params.require(:headquarter).permit(:name, :location, :credits, :description, :image)
  end

  def set_headquarter
    @headquarter = Headquarter.first
  end
end