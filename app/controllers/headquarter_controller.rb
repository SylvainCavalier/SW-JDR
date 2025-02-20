class HeadquarterController < ApplicationController
  before_action :set_headquarter

  def show
  end

  def edit
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
    @headquarter_inventory_items = @headquarter.headquarter_inventory_objects.includes(:inventory_object)
  end

  def remove_item
    item = @headquarter.headquarter_inventory_objects.find(params[:id])
    if item.quantity > 1
      item.update(quantity: item.quantity - 1)
    else
      item.destroy
    end
    redirect_to headquarter_inventory_path, notice: "#{item.inventory_object.name} supprimé."
  end

  def give_item
    item = @headquarter.headquarter_inventory_objects.find(params[:item_id])
    recipient = User.find(params[:recipient_id])
    
    if item.quantity >= params[:quantity].to_i
      UserInventoryObject.create(user: recipient, inventory_object: item.inventory_object, quantity: params[:quantity])
      item.update(quantity: item.quantity - params[:quantity].to_i)
      item.destroy if item.quantity.zero?
      redirect_to headquarter_inventory_path, notice: "#{params[:quantity]} #{item.inventory_object.name} donnés à #{recipient.username}."
    else
      redirect_to headquarter_inventory_path, alert: "Quantité invalide."
    end
  end

  def buildings
    @buildings = @headquarter.buildings
    @available_buildings = Building.all - @buildings
  end

  def personnel
    @personnel = @headquarter.pets
  end

  def shop
  end

  def defense
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

  private

  def headquarter_params
    params.require(:headquarter).permit(:name, :location, :credits, :description, :image)
  end

  def set_headquarter
    @headquarter = Headquarter.first
  end
end