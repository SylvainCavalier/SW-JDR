class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:medipack, :healobjects, :buy_inventory_object, :inventory, :sell_item, :give_item]

  def toggle_shield
    shield_type = params[:shield_type]
    user = current_user
  
    case shield_type
    when "energy"
      if user.shield_state
        user.deactivate_all_shields
      elsif user.can_activate_energy_shield?
        user.activate_energy_shield
      else
        render json: { success: false, message: "Recharge nécessaire pour activer le bouclier d'énergie." }, status: :unprocessable_entity and return
      end
    when "echani"
      if user.echani_shield_state
        user.deactivate_all_shields
      elsif user.can_activate_echani_shield?
        user.activate_echani_shield
      else
        render json: { success: false, message: "Recharge nécessaire pour activer le bouclier Échani." }, status: :unprocessable_entity and return
      end
    else
      render json: { success: false, message: "Type de bouclier invalide." }, status: :unprocessable_entity and return
    end
  
    # Diffusion des mises à jour
    user.broadcast_energy_shield_update if shield_type == "energy"
    user.broadcast_echani_shield_update if shield_type == "echani"
  
    render json: {
      success: true,
      shield_state: user.shield_state,
      echani_shield_state: user.echani_shield_state
    }
  end

  def recharger_bouclier
    shield_type = params[:shield_type]
    recharge_cost = if shield_type == "energy"
                      ((current_user.shield_max || 0) - (current_user.shield_current || 0)) * 10
                    elsif shield_type == "echani"
                      ((current_user.echani_shield_max || 0) - (current_user.echani_shield_current || 0)) * 10
                    end
  
    if current_user.credits >= recharge_cost
      current_user.transaction do
        if shield_type == "energy"
          current_user.update!(
            shield_current: current_user.shield_max,
            credits: current_user.credits - recharge_cost
          )
          current_user.broadcast_energy_shield_update
        elsif shield_type == "echani"
          current_user.update!(
            echani_shield_current: current_user.echani_shield_max,
            credits: current_user.credits - recharge_cost
          )
          current_user.broadcast_echani_shield_update
        end
        current_user.broadcast_credits_update
      end
  
      redirect_to root_path, notice: "Bouclier rechargé avec succès."
    else
      redirect_to root_path, alert: "Crédits insuffisants. (Sale pauvre)"
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
    @res_corp_skill = @user.user_skills.find_or_initialize_by(skill: Skill.find_by(name: "Résistance Corporelle"))
    @vitesse_skill = @user.user_skills.find_or_initialize_by(skill: Skill.find_by(name: "Vitesse"))
    @reparation_skill = current_user.user_skills.find_by(skill: Skill.find_by(name: "Réparation"))
  end
  
  def update_settings
    @user = current_user
  
    @user.medicine_mastery = params[:user][:medicine_mastery].to_i
    @user.medicine_bonus = params[:user][:medicine_bonus].to_i
    @user.res_corp_mastery = params[:user][:res_corp_mastery].to_i
    @user.res_corp_bonus = params[:user][:res_corp_bonus].to_i
    @user.vitesse_mastery = params[:user][:vitesse_mastery].to_i
    @user.vitesse_bonus = params[:user][:vitesse_bonus].to_i
    @user.reparation_mastery = params[:user][:reparation_mastery].to_i
    @user.reparation_bonus = params[:user][:reparation_bonus].to_i
  
    # Gestion du don "Homéopathie"
    if params[:user].key?(:homeopathie)
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
    end
  
    # Gestion de la "Chance du Contrebandier"
    if params[:user][:luck] == "1"
      @user.luck = true
      Rails.logger.debug "✅ 'Chance du Contrebandier' activée pour #{@user.username}."
    else
      @user.luck = false
      Rails.logger.debug "❌ 'Chance du Contrebandier' désactivée pour #{@user.username}."
    end
  
    if @user.update(user_params)
      update_skill("Médecine", @user.medicine_mastery, @user.medicine_bonus)
      update_skill("Résistance Corporelle", @user.res_corp_mastery, @user.res_corp_bonus)
      update_skill("Vitesse", @user.vitesse_mastery, @user.vitesse_bonus)
      update_skill("Réparation", @user.reparation_mastery, @user.reparation_bonus) # ✅ Sécurisation de "Réparation"
  
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
    @users = User.joins(:group).where(groups: { name: "PJ" }).order(:username).to_a
    @users.delete(current_user) # Retire le current_user de la liste triée
    @users.unshift(current_user) # Ajoute le current_user au début
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

  def dice
    # Pas de logique particulière ici, on affiche simplement la vue
  end

  def group_luck_roll
    @users = User.all
    results = @users.map do |user|
      { username: user.username, score: rand(1..12) }
    end

    # Identifier le gagnant et le perdant
    highest = results.max_by { |r| r[:score] }
    lowest = results.min_by { |r| r[:score] }

    # Ajouter les annotations "Wow!" et "Looser!"
    results.each do |result|
      result[:status] = if result == highest
                          "Wow!"
                        elsif result == lowest
                          "Looser!"
                        end
    end

    # Diffuser les résultats via Turbo Stream
    Turbo::StreamsChannel.broadcast_replace_to(
      "global_notifications",
      target: "group-luck-popup",
      partial: "dice/group_luck_popup",
      locals: { results: results }
    )

    render json: { success: true, message: "Jet de groupe lancé avec succès !" }
  end

  def inventory
    @inventory_items = @user.user_inventory_objects
                            .includes(:inventory_object)
                            .order('inventory_objects.category ASC, inventory_objects.name ASC')
  end

  def sell_item
    item = @user.user_inventory_objects.find(params[:item_id])
    quantity_to_sell = params[:quantity].to_i
    if item.quantity >= quantity_to_sell
      item.quantity -= quantity_to_sell
      item.save!
      credits_earned = (item.inventory_object.price / 5) * quantity_to_sell
      @user.update!(credits: @user.credits + credits_earned)
      flash[:success] = "#{quantity_to_sell} #{item.inventory_object.name} vendu(s) pour #{credits_earned} crédits."
    else
      flash[:error] = "Vous ne possédez pas assez d'objets pour effectuer cette vente."
    end
    redirect_to inventory_user_path(@user)
  end

  def give_item
    item = @user.user_inventory_objects.find(params[:item_id])
    recipient = User.find(params[:recipient_id])
    quantity_to_give = params[:quantity].to_i
    if item.quantity >= quantity_to_give
      item.quantity -= quantity_to_give
      item.save!
      recipient_item = recipient.user_inventory_objects.find_or_create_by(inventory_object: item.inventory_object)
      recipient_item.quantity ||= 0
      recipient_item.quantity += quantity_to_give
      recipient_item.save!
      flash[:success] = "#{quantity_to_give} #{item.inventory_object.name} donné(s) à #{recipient.username}."
    else
      flash[:error] = "Vous ne possédez pas assez d'objets pour effectuer ce don."
    end
    redirect_to inventory_user_path(@user)
  end

  def remove_item
    item = current_user.user_inventory_objects.find_by(id: params[:item_id])
  
    if item
      Rails.logger.debug "🛠️ Objet trouvé: #{item.inspect}" # Vérifier si l'objet est bien trouvé
      
      if item.quantity > 1
        Rails.logger.debug "🔻 Décrémentation de la quantité de #{item.inventory_object.name}"
        item.update!(quantity: item.quantity - 1)
        flash[:notice] = "1 #{item.inventory_object.name} a été retiré de votre inventaire."
      else
        Rails.logger.debug "❌ Suppression de l'objet car quantité = 0"
        item.destroy  # Supprime uniquement si quantité = 0
        flash[:notice] = "L'objet #{item.inventory_object.name} a été complètement retiré de votre inventaire."
      end
    else
      Rails.logger.debug "⚠️ Objet introuvable"
      flash[:alert] = "Objet introuvable."
    end
  
    redirect_back(fallback_location: inventory_user_path(current_user))
  end

  def injections
    @user_injections = current_user.user_inventory_objects
                                   .includes(:inventory_object)
                                   .where("quantity > 0")
                                   .where(inventory_objects: { category: "injection" })
  end
  
  def equip_injection
    injection_id = params[:injection_id]
    injection = InventoryObject.find_by(id: injection_id)
    
    if current_user.user_inventory_objects.exists?(inventory_object_id: injection_id)
      current_user.equip_injection(injection_id)
      current_user.decrement_inventory!(injection_id)
      current_user.apply_injection_effects

      unless %w[Injection de trinitine Injection de bio-rage].include?(injection.name)
        current_user.decrement!(:hp_current, 2)
      end
      
      redirect_to injections_user_path(current_user), notice: "Injection active : #{current_user.active_injection_object&.name}."
    else
      redirect_to injections_user_path(current_user), alert: "Injection non disponible."
    end
  end

  def deactivate_injection
    if current_user.active_injection
      current_user.remove_injection_effects
      current_user.unequip_injection

      redirect_to injections_user_path(current_user), notice: "Injection désactivée avec succès."
    else
      redirect_to injections_user_path(current_user), alert: "Aucune injection active à désactiver."
    end
  end

  def use_trinitine
    session[:trinitine_uses] ||= 0
    session[:trinitine_uses] += 1
  
    if session[:trinitine_uses] <= 3
      current_user.increment!(:hp_current, rand(1..6))
      flash[:notice] = "Vous avez utilisé la Trinitine (#{session[:trinitine_uses]}/3)."
    end
  
    if session[:trinitine_uses] >= 3
      session.delete(:trinitine_uses)
      current_user.unequip_injection
      flash[:alert] = "Injection de Trinitine désactivée après 3 utilisations."
    end
  
    redirect_to injections_user_path(current_user)
  end

  def implants
    @user_implants = current_user.user_inventory_objects
                                 .includes(:inventory_object)
                                 .where("quantity > 0")
                                 .where(inventory_objects: { category: "implant" })
  end

  def equip_implant
    implant_id = params[:implant_id]
  
    if current_user.user_inventory_objects.exists?(inventory_object_id: implant_id)
      current_user.equip_implant(implant_id)
      current_user.apply_implant_effects
      redirect_to implants_user_path(current_user), notice: "Implant équipé : #{current_user.active_implant_object&.name}."
    else
      redirect_to implants_user_path(current_user), alert: "Implant non disponible."
    end
  end
  
  def unequip_implant
    if current_user.active_implant
      current_user.remove_implant_effects
      current_user.unequip_implant
      redirect_to implants_user_path(current_user), notice: "Implant déséquipé avec succès."
    else
      redirect_to implants_user_path(current_user), alert: "Aucun implant actif à déséquiper."
    end
  end

  def sphero
    @active_sphero = current_user.spheros.includes(sphero_skills: :skill).find_by(active: true)
    @spheros = current_user.spheros.includes(sphero_skills: :skill).where(active: false)
  end

  def edit_notes
    @user = User.find(params[:id])
  end

  def update_notes
    @user = User.find(params[:id])
  
    if @user.update(notes: params[:user][:notes])
      flash[:notice] = "Notes mises à jour avec succès."
    else
      flash[:alert] = "Erreur lors de la mise à jour des notes."
    end
  
    redirect_to edit_notes_user_path(@user)
  end

  def avatar_upload
    @user = User.find(params[:id])
    if @user.update(avatar_params)
      redirect_to root_path, notice: "Avatar mis à jour avec succès !"
    else
      redirect_to root_path, alert: "Erreur lors de l'upload."
    end
  end
  
  private
  
  def avatar_params
    params.require(:user).permit(:avatar)
  end

  def update_skill(skill_name, mastery, bonus)
    skill = Skill.find_by(name: skill_name)
    return unless skill
  
    user_skill = current_user.user_skills.find_or_initialize_by(skill: skill)
    user_skill.update(mastery: mastery.to_i, bonus: bonus.to_i)
  end

  def user_params
    params.require(:user).permit(
      :robustesse,
      :homeopathie,
      :luck,
      :medicine_mastery,
      :medicine_bonus,
      :res_corp_mastery,
      :res_corp_bonus,
      :reparation_mastery,
      :reparation_bonus,
      :active_injection,
      :active_implant
    )
  end
  
  def set_user
    @user = User.find(params[:id])
  end
end
