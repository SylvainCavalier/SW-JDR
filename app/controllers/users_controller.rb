class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:medipack, :healobjects, :buy_inventory_object]

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

  def medipack
    render :medipack
  end

  def healobjects
    @heal_objects = InventoryObject.where(category: 'soins').where(rarity: ['Commun', 'Unco'])
  end

  def buy_inventory_object
    inventory_object = InventoryObject.find(params[:inventory_object_id])
    user_inventory_object = @user.user_inventory_objects.find_or_initialize_by(inventory_object: inventory_object)
  
    if @user.credits >= inventory_object.price
      @user.credits -= inventory_object.price
      user_inventory_object.quantity ||= 0
      user_inventory_object.quantity += 1
  
      ActiveRecord::Base.transaction do
        @user.save!
        user_inventory_object.save!
      end
  
      render json: { new_quantity: user_inventory_object.quantity }, status: :ok
    else
      render json: { error: "Crédits insuffisants" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Utilisateur ou objet introuvable" }, status: :not_found
  end

  def heal_player
    player = User.find(params[:player_id])
    inventory_object = current_user.user_inventory_objects.find_by(inventory_object_id: params[:item_id])
  
    if inventory_object.nil? || inventory_object.quantity <= 0
      render json: { error: "Objet de soin invalide ou quantité insuffisante." }, status: :unprocessable_entity
      return
    end
  
    dice_roll = (1..current_user.medicine_mastery).map { rand(1..6) }.sum + current_user.medicine_bonus
    heal_amount = (dice_roll / 2.0).ceil
  
    new_hp = [player.hp_current + heal_amount, player.hp_max].min
    inventory_object.quantity -= 1
  
    ActiveRecord::Base.transaction do
      inventory_object.save!
      player.update!(hp_current: new_hp)
    end
  
    render json: { player_id: player.id, new_hp: new_hp, item_quantity: inventory_object.quantity }
  end

  private

  def user_params
    params.require(:user).permit(:robustesse, :medicine_mastery, :medicine_bonus)
  end
  
  def set_user
    @user = User.find(params[:id])
  end
end
