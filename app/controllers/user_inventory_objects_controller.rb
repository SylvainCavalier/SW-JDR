class UserInventoryObjectsController < ApplicationController
  before_action :set_user_inventory_object, only: [:use]
  before_action :set_target_user, only: [:use]

  def use
    if @user_inventory_object.quantity > 0
      healing_points = calculate_healing_points(@user_inventory_object)
      @target_user.hp_current = [@target_user.hp_current + healing_points, @target_user.hp_max].min
      @target_user.save
      
      @user_inventory_object.update(quantity: @user_inventory_object.quantity - 1)
      
      redirect_to user_inventory_path(current_user), notice: "Vous avez utilisé #{@user_inventory_object.inventory_object.name} et restauré #{healing_points} PV."
    else
      redirect_to user_inventory_path(current_user), alert: "Vous n'avez plus cet objet en stock."
    end
  end

  private

  def set_user_inventory_object
    @user_inventory_object = UserInventoryObject.find(params[:id])
  end

  def set_target_user
    @target_user = User.find(params[:target_user_id])
  end

  def calculate_healing_points(user_inventory_object)
    case user_inventory_object.inventory_object.name
    when "Medipack"
      (current_user.medicine_skill_roll / 2).floor
    when "Medipack +"
      (current_user.medicine_skill_roll / 2).floor + roll_dice(1)
    when "Medipack Deluxe"
      current_user.medicine_skill_roll
    else
      0
    end
  end

  def roll_dice(number_of_dice)
    Array.new(number_of_dice) { rand(1..6) }.sum
  end
end