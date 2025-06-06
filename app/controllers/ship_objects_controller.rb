class ShipObjectsController < ApplicationController
  before_action :set_ship_object, only: [:edit, :update, :destroy]
  before_action :set_ship, only: [:new, :create]
  before_action :authenticate_user!

  def new
    @ship_object = ShipObject.new(ship: @ship)
  end

  def create
    @ship_object = ShipObject.new(ship_object_params)
    @ship_object.ship = @ship
    if @ship_object.save
      redirect_to ship_path(@ship), notice: "Objet ajouté à l'inventaire."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ship_object.update(ship_object_params)
      redirect_to ship_path(@ship_object.ship), notice: "Objet modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    ship = @ship_object.ship
    @ship_object.destroy
    redirect_to ship_path(ship), notice: "Objet supprimé."
  end

  private

  def set_ship_object
    @ship_object = ShipObject.find(params[:id])
  end

  def set_ship
    @ship = Ship.find(params[:ship_id])
  end

  def ship_object_params
    params.require(:ship_object).permit(:name, :quantity, :description)
  end
end
