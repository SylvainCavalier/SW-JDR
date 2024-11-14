class UsersController < ApplicationController
  before_action :authenticate_user!

  def toggle_shield
    new_state = params[:shield_state] == "true"
    current_user.update(shield_state: new_state)
    respond_to do |format|
      format.json { render json: { shield_state: current_user.shield_state } }
    end
  end

  def update_hp
    user = User.find(params[:id])
    new_hp = params[:hp_current].to_i
  
    if user.update(hp_current: new_hp)
      render json: { success: true, hp_current: user.hp_current }
    else
      render json: { success: false, error: "Impossible de mettre à jour les PV" }, status: :unprocessable_entity
    end
  end

  def purchase_hp
    user = current_user
    hp_increase = params[:hp_increase].to_i
    xp_cost = params[:xp_cost].to_i
  
    if user.xp >= xp_cost
      user.update(hp_max: user.hp_max + hp_increase, xp: user.xp - xp_cost)
      render json: { success: true, hp_max: user.hp_max, xp: user.xp }
    else
      render json: { success: false, error: "Not enough XP" }, status: :unprocessable_entity
    end
  end

  def recharger_bouclier
    user = User.find(params[:id])
    recharge_cost = (user.shield_max - user.shield_current) * 10

    if user.credits >= recharge_cost
      user.update(shield_current: user.shield_max, credits: user.credits - recharge_cost)
      render json: { success: true, shield_current: user.shield_current, credits: user.credits }
    else
      render json: { success: false, message: "Crédits insuffisants" }, status: :unprocessable_entity
    end
  end

  def spend_xp
    user = User.find(params[:id])
  
    if user.xp > 0
      user.decrement!(:xp)
      render json: { xp: user.xp }, status: :ok
    else
      render json: { error: "Pas assez de points d'XP" }, status: :unprocessable_entity
    end
  end

  def settings
    @user = current_user
    @medicine_skill = @user.user_skills.find_or_initialize_by(skill: Skill.find_by(name: "Médecine"))
  end
  
  def update_settings
    @user = current_user
    
    @user.medicine_mastery = params[:user][:medicine_mastery].to_i
    @user.medicine_bonus = params[:user][:medicine_bonus].to_i
  
    if @user.update(user_params)
      medicine_skill = @user.user_skills.find_or_initialize_by(skill: Skill.find_by(name: "Médecine"))
      medicine_skill.update(
        mastery: @user.medicine_mastery,
        bonus: @user.medicine_bonus
      )
      
      redirect_to settings_user_path(@user), notice: "Réglages mis à jour avec succès."
    else
      render :settings, alert: "Erreur lors de la mise à jour des réglages."
    end
  end

  private

  def user_params
    params.require(:user).permit(:robustesse, :medicine_mastery, :medicine_bonus)
  end
  
  def set_user
    @user = User.find(params[:id])
  end
end
