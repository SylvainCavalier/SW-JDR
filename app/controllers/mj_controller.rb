class MjController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_mj

  # Chargement des utilisateurs avant d'afficher la page des dégâts
  def infliger_degats
    @users = User.where(group_id: Group.find_by(name: "PJ").id)
  end

  # Action pour appliquer les dégâts
  def apply_damage
    user = User.find(damage_params[:user_id])
    damage = damage_params[:damage].to_i

    if user.shield_state && user.shield_current > 0
      new_shield_value = [user.shield_current - damage, 0].max
      user.update(shield_current: new_shield_value)
      message = "Bouclier a pris #{damage} dégâts."
    else
      new_hp_value = [user.hp_current - damage, 0].max
      user.update(hp_current: new_hp_value)
      message = "Le joueur a pris #{damage} dégâts."
    end

    respond_to do |format|
      format.json { render json: { success: true, hp_current: user.hp_current, shield_current: user.shield_current, message: message } }
    end
  end

  def fixer_pv_max
    @users = User.where(group_id: Group.find_by(name: "PJ").id)
  end

  def update_pv_max
    @users = User.where(group_id: Group.find_by(name: "PJ").id)
    @users.each do |user|
      pv_max = params[:pv_max][user.id.to_s].to_i
      user.update(hp_max: pv_max)
    end
    redirect_to fixer_pv_max_path, notice: "PV Max mis à jour"
  end

  private

  def authorize_mj
    unless current_user.group.name == "MJ"
      redirect_to root_path, alert: "Accès refusé."
    end
  end

  def damage_params
    params.permit(:user_id, :damage)
  end
end
