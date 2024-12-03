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

  def medipack
    @users = User.joins(:group).where(groups: { name: "PJ" })
    @user_inventory_objects = current_user.user_inventory_objects.includes(:inventory_object)
  end

  def heal_player
    Rails.logger.debug "➡️ Début de l'action heal_player"
  
    begin
      Rails.logger.debug "Params reçus: #{params.inspect}"
  
      player = User.find(params[:player_id])
      Rails.logger.debug "👤 Joueur chargé: #{player.inspect}"
  
      heal_item = current_user.user_inventory_objects.find_by(inventory_object_id: params[:item_id])
      Rails.logger.debug "🩹 Objet de soin chargé: #{heal_item.inspect}"
  
      if heal_item.nil? || heal_item.quantity <= 0
        Rails.logger.debug "❌ Objet de soin invalide ou quantité insuffisante."
        render json: { error: "Objet de soin invalide ou quantité insuffisante." }, status: :unprocessable_entity
        return
      end
  
      medicine_skill = current_user.user_skills.joins(:skill).find_by(skills: { name: 'Médecine' })
      medicine_mastery = medicine_skill&.mastery || 0
      medicine_bonus = medicine_skill&.bonus || 0

      Rails.logger.debug "🎲 Compétence Médecine - Mastery: #{medicine_mastery}, Bonus: #{medicine_bonus}"
      Rails.logger.debug "🎲 Début du calcul des dés"

      dice_roll = (1..medicine_mastery).map { rand(1..6) }.sum + medicine_bonus
      heal_amount = (dice_roll / 2.0).ceil

      Rails.logger.debug "🎲 Résultat du lancer de dés : #{dice_roll}, Points de soin : #{heal_amount}"

      new_hp = [player.hp_current + heal_amount, player.hp_max].min
      heal_item.quantity -= 1
      Rails.logger.debug "🩹 Quantité mise à jour pour l'objet de soin: #{heal_item.quantity}"
  
      ActiveRecord::Base.transaction do
        Rails.logger.debug "🔄 Début de la transaction"
        heal_item.save! if heal_item.changed?
        Rails.logger.debug "🩹 Objet de soin sauvegardé"
        player.update!(hp_current: new_hp) if player.hp_current != new_hp
        Rails.logger.debug "👤 PV du joueur mis à jour"
      end
      Rails.logger.debug "✅ Transaction effectuée avec succès"
  
      render json: {
        player_id: player.id,
        new_hp: new_hp,
        item_quantity: heal_item.quantity,
        healed_points: heal_amount,
        player_name: player.username
      }
      Rails.logger.debug "📤 JSON rendu avec succès"
  
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "⚠️ Erreur lors de la transaction : #{e.message}"
      render json: { error: "Une erreur s'est produite lors de la mise à jour des données." }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "⚠️ Erreur inattendue : #{e.message}"
      render json: { error: "Une erreur inattendue s'est produite." }, status: :internal_server_error
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
