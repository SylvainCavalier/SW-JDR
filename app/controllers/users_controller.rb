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

    # Gestion du don "Homéopathie"
    homeopathie_item = InventoryObject.find_by(name: "Homéopathie")
    if params[:user][:homeopathie] == "1"
      user_inventory_object = @user.user_inventory_objects.find_or_initialize_by(inventory_object: homeopathie_item)
      user_inventory_object.quantity = 1
      user_inventory_object.save!
      Rails.logger.debug "✅ 'Homéopathie' ajoutée à l'utilisateur #{@user.username}."
    else
      user_inventory_object = @user.user_inventory_objects.find_by(inventory_object: homeopathie_item)
      if user_inventory_object
        user_inventory_object.update(quantity: 0)
        Rails.logger.debug "❌ 'Homéopathie' retirée de l'utilisateur #{@user.username}."
      end
    end
  
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
  
      # Chargement de l'utilisateur cible
      user = User.find(params[:player_id])
      Rails.logger.debug "👤 Joueur chargé: #{user.inspect}"
  
      # Chargement de l'objet de soin
      heal_item = current_user.user_inventory_objects.find_by(inventory_object_id: params[:item_id])
      inventory_object = heal_item&.inventory_object || InventoryObject.find_by(id: params[:item_id])
      Rails.logger.debug "📦 Objet d'inventaire : #{inventory_object.inspect}"
  
      if inventory_object.nil?
        Rails.logger.debug "❌ Objet de soin introuvable."
        render json: { error: "Objet de soin introuvable." }, status: :unprocessable_entity
        return
      end
  
      # Gestion spécifique pour "Homéopathie"
      if inventory_object.name == "Homéopathie"
        Rails.logger.debug "💊 Homéopathie détectée. Ignorer les vérifications de quantité."
  
        if user.hp_current < user.hp_max - 5
          render json: { error_message: "Homéopathie ne peut être utilisée que si le personnage a perdu 5 PV ou moins." }, status: :unprocessable_entity
          return
        end
      elsif heal_item.nil? || heal_item.quantity <= 0
        Rails.logger.debug "❌ Objet de soin invalide ou quantité insuffisante."
        render json: { error: "Objet de soin invalide ou quantité insuffisante." }, status: :unprocessable_entity
        return
      end
  
      # Vérification des PV actuels
      if user.hp_current >= user.hp_max
        render json: { error_message: "Les PV de ce personnage sont déjà au maximum !" }, status: :unprocessable_entity
        return
      end
  
      # Application des effets
      healed_points, new_status = inventory_object.apply_effects(user, current_user)
      Rails.logger.debug "❤️ Points de soin : #{healed_points}, Nouveau statut : #{new_status.inspect}"
  
      if healed_points <= 0 && new_status.nil?
        render json: { error_message: "Cet objet ne peut pas être utilisé dans ce contexte." }, status: :unprocessable_entity
        return
      end
  
      new_hp = [user.hp_current + healed_points, user.hp_max].min
      Rails.logger.debug "🔄 Nouveau PV : #{new_hp}"
  
      # Transaction
      ActiveRecord::Base.transaction do
        Rails.logger.debug "🔄 Début de la transaction"
  
        # Mise à jour de la quantité sauf pour "Homéopathie"
        if inventory_object.name != "Homéopathie" && healed_points > 0
          heal_item.quantity -= 1
          heal_item.save!
          Rails.logger.debug "🩹 Quantité mise à jour : #{heal_item.quantity}"
        end
  
        # Mise à jour des PV
        user.update!(hp_current: new_hp)
        user.broadcast_hp_update
        Rails.logger.debug "👤 PV mis à jour"
  
        # Mise à jour du statut si nécessaire
        if new_status
          user.set_status(new_status)
          user.broadcast_status_update
          Rails.logger.debug "🔄 Statut mis à jour : #{new_status}"
        end
      end
  
      Rails.logger.debug "✅ Transaction effectuée avec succès"
  
      # Réponse JSON
      render json: {
        user_id: user.id,
        new_hp: new_hp,
        item_quantity: heal_item&.quantity || "illimité",
        healed_points: healed_points,
        player_name: user.username,
        new_status: new_status
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

  def patch
    @user_inventory_objects = current_user.user_inventory_objects
                                          .includes(:inventory_object)
                                          .where("quantity > 0")
                                          .where(inventory_objects: { category: "patch" })
  end

  def equip_patch
    patch_id = params[:patch_id]
  
    if current_user.user_inventory_objects.exists?(inventory_object_id: patch_id)
      current_user.equip_patch(patch_id)
      redirect_to patch_user_path(current_user), notice: "Patch équipé avec succès."
    else
      redirect_to patch_user_path(current_user), alert: "Patch non disponible."
    end
  end

  def use_patch
    if current_user.patch.present?
      equipped_patch = current_user.equipped_patch
      inventory_object = current_user.user_inventory_objects.find_by(inventory_object_id: equipped_patch.id)
  
      ActiveRecord::Base.transaction do
        if equipped_patch.name == "Poisipatch"
          if current_user.statuses.exists?(name: "Empoisonné")
            current_user.set_status("En forme")
            Rails.logger.info "✔️ Poisipatch activé : statut Empoisonné guéri."
          else
            redirect_to patch_user_path(current_user), alert: "Le Poisipatch ne peut être utilisé que si vous êtes empoisonné."
            return
          end
        elsif equipped_patch.name == "Traumapatch"
          healed_points = rand(1..6)
          new_hp = [current_user.hp_current + healed_points, current_user.hp_max].min
          current_user.update!(hp_current: new_hp)
          Rails.logger.info "✔️ Traumapatch activé : +#{healed_points} PV récupérés."
        elsif equipped_patch.name == "Stimpatch"
          if current_user.statuses.exists?(name: "Sonné")
            current_user.set_status("En forme")
            Rails.logger.info "✔️ Stimpatch activé : statut Sonné guéri."
          else
            redirect_to patch_user_path(current_user), alert: "Le Stimpatch ne peut être utilisé que si vous êtes sonné."
            return
          end
        end
  
        # Gestion de la quantité et déséquipement du patch
        if inventory_object.present? && inventory_object.quantity > 0
          inventory_object.decrement!(:quantity)
        end
        current_user.update!(patch: nil)
      end
  
      redirect_to patch_user_path(current_user), notice: "Patch « #{equipped_patch.name} » utilisé avec succès."
    else
      redirect_to patch_user_path(current_user), alert: "Aucun patch actuellement équipé."
    end
  rescue => e
    Rails.logger.error "Erreur lors de l'utilisation du patch : #{e.message}"
    redirect_to patch_user_path(current_user), alert: "Une erreur est survenue lors de l'utilisation du patch."
  end

  private

  def user_params
    params.require(:user).permit(:robustesse, :homeopathie, :medicine_mastery, :medicine_bonus)
  end
  
  def set_user
    @user = User.find(params[:id])
  end
end
