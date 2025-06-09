class ShipObjectsController < ApplicationController
  before_action :set_ship
  before_action :set_ship_object, only: [:edit, :update, :destroy]
  before_action :authenticate_user!

  def new
    @ship_object = ShipObject.new(ship: @ship)
  end

  def create
    @ship_object = @ship.ship_objects.build(ship_object_params)

    respond_to do |format|
      if @ship_object.save
        format.json { 
          render json: { 
            success: true, 
            html: render_to_string(partial: 'ships/object_row', locals: { object: @ship_object, ship: @ship }, formats: [:html])
          }
        }
      else
        format.json { render json: { success: false, error: @ship_object.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @ship_object.update(ship_object_params)
        format.json { render json: { success: true } }
      else
        format.json { render json: { success: false, error: @ship_object.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @ship_object.destroy
    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end

  private

  def set_ship
    @ship = current_user.group.ships.find(params[:ship_id])
  end

  def set_ship_object
    @ship_object = @ship.ship_objects.find(params[:id])
  end

  def ship_object_params
    params.require(:ship_object).permit(:name, :quantity, :description)
  end
end
