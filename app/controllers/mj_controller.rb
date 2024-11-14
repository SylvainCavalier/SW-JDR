class MjController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_mj

  def infliger_degats
    @users = User.where(group_id: Group.find_by(name: "PJ").id)
  end

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
    pv_max_params.each do |user_id, hp_max_value|
      user = User.find(user_id)
      user.update(hp_max: hp_max_value.to_i)
    end
  
    redirect_to fixer_pv_max_path, notice: "PV Max mis à jour"
  end

  def donner_xp
    @players = User.where(group: Group.find_by(name: "PJ"))
  end

  def attribution_xp
    xp_to_add = xp_params[:xp].to_i
    give_to_all = xp_params[:give_to_all] == "true"
    user_id = xp_params[:user_id]
    xp_updates = []
  
    if give_to_all
      User.where(group: Group.find_by(name: "PJ")).each do |user|
        user.apply_xp_bonus(xp_to_add)
        xp_updates << { id: user.id, xp: user.xp }
      end
    elsif user_id.present?
      user = User.find(user_id)
      user.apply_xp_bonus(xp_to_add)
      xp_updates << { id: user.id, xp: user.xp }
    end
  
    respond_to do |format|
      format.turbo_stream do
        render partial: "pages/attribution_xp", locals: { xp_updates: xp_updates }
      end
      format.html { redirect_to donner_xp_path, notice: "XP mis à jour !" }
    end
  end
  
  private
  
  def xp_params
    params.require(:xp).permit(:xp, :user_id, :give_to_all)
  end

  def authorize_mj
    unless current_user.group.name == "MJ"
      redirect_to root_path, alert: "Accès refusé."
    end
  end

  def damage_params
    params.permit(:user_id, :damage, :authenticity_token)
  end

  def pv_max_params
    params.require(:pv_max).permit!
  end
end
