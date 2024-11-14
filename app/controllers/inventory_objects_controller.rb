class InventoryObjectsController < ApplicationController
  before_action :set_user

  def index
    @inventory_objects = @user.inventory_objects
  end

  def create
    @inventory_object = @user.inventory_objects.new(inventory_object_params)
    if @inventory_object.save
      redirect_to user_inventory_objects_path(@user), notice: "Objet ajouté à l'inventaire."
    else
      render :index, alert: "Erreur lors de l'ajout de l'objet."
    end
  end

  def destroy
    @inventory_object = @user.inventory_objects.find(params[:id])
    @inventory_object.destroy
    redirect_to user_inventory_objects_path(@user), notice: "Objet supprimé de l'inventaire."
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def inventory_object_params
    params.require(:inventory_object).permit(:name, :description, :price)
  end
end