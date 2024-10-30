class UsersController < ApplicationController
  before_action :authenticate_user!

  def toggle_shield
    current_user.update(shield_state: !current_user.shield_state)
    respond_to do |format|
      format.json { render json: { shield_state: current_user.shield_state } }
    end
  end

  def update_hp
    hp_current = params[:hp_current].to_i
    if hp_current.between?(-10, (current_user.hp_max + 3))
      current_user.update(hp_current: hp_current)
      render json: { success: true, hp_current: current_user.hp_current }
    else
      render json: { success: false, message: "Valeur de PV incorrecte" }
    end
  end
end
