class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:medipack, :healobjects, :buy_inventory_object, :inventory, :sell_item, :give_item, :show]
  
  def show
    @user = User.find(params[:id])
    # Stocker la page d'origine seulement si on vient d'une page principale (pas pet/user)
    if request.referer.present? && 
       !request.referer.include?(user_path(@user)) &&
       !request.referer.include?('/pets/') &&
       !request.referer.include?('/users/')
      session[:return_to] = request.referer
    end
    
    # Variables pour les compétences
    @skills = Skill.includes(:carac)
    @user_skills = @skills.map do |skill|
      @user.user_skills.find_or_initialize_by(skill: skill) do |us|
        us.mastery = 0
        us.bonus = 0
      end
    end
    @user_caracs = @user.user_caracs.includes(:carac).index_by { |uc| uc.carac.name }

    # Exclure 'Précision' pour les utilisateurs
    filtered_skills = @user_skills.reject { |us| us.skill.name == "Précision" }

    # Grouper et trier selon SKILL_ORDER
    @grouped_skills = {}
    ApplicationHelper::SKILL_ORDER.each do |carac, skill_names|
      skills_for_carac = filtered_skills.select { |us| us.skill.carac&.name == carac }
      # Trier selon l'ordre défini
      ordered = skill_names.map { |name| skills_for_carac.find { |us| us.skill.name == name } }.compact
      @grouped_skills[carac] = ordered
    end

    @jedi_skills = filtered_skills.select { |us| ["Contrôle", "Sens", "Altération"].include?(us.skill.name) }
    @corporelle_skill = filtered_skills.find { |us| us.skill.name == "Résistance Corporelle" }

    # Variables pour l'équipement
    @equipment_slots = EQUIPMENT_SLOTS
    @equipments_by_slot = @user.equipments.group_by(&:slot)
    @user_implants = @user.user_inventory_objects
                         .includes(:inventory_object)
                         .where("quantity > 0")
                         .where(inventory_objects: { category: "implant" })
    @user_inventory_objects = @user.user_inventory_objects
                                 .includes(:inventory_object)
                                 .where("quantity > 0")
                                 .where(inventory_objects: { category: "patch" })
    @user_injections = @user.user_inventory_objects
                           .includes(:inventory_object)
                           .where("quantity > 0")
                           .where(inventory_objects: { category: "injection" })

    # Variables pour l'inventaire
    @inventory_items = @user.user_inventory_objects.includes(:inventory_object)
  end

  def equip_equipment
    @user = User.find(params[:id])
    item = @user.equipments.find(params[:equipment_id])
    @user.equipments.where(slot: item.slot).update_all(equipped: false)
    item.update!(equipped: true)
  end
  
  def add_equipment
    @user = User.find(params[:id])
    new_item = @user.equipments.create!(
      slot: params[:slot],
      name: params[:name],
      effect: params[:effect],
      equipped: true
    )
    # déséquipe les autres dans le même slot
    @user.equipments.where(slot: params[:slot]).where.not(id: new_item.id).update_all(equipped: false)
  end
  
  def remove_equipment
    @user = User.find(params[:id])
    item = @user.equipments.find_by(slot: params[:slot], equipped: true)
    item.update!(equipped: false) if item
  end
  
  def delete_equipment
    @user = User.find(params[:id])
    item = @user.equipments.find(params[:equipment_id])

    ActiveRecord::Base.transaction do
      item.update!(equipped: false) if item.equipped?
      item.destroy!
    end
  end

  def skills
    @user = User.find(params[:id])
    @skills = Skill.includes(:carac).order(:name)
    @user_skills = @skills.map do |skill|
      @user.user_skills.find_or_initialize_by(skill: skill) do |us|
        us.mastery = 0
        us.bonus = 0
      end
    end
  
    @user_caracs = @user.user_caracs.includes(:carac).index_by { |uc| uc.carac.name }
  
    # Regrouper les skills par carac sauf les spéciaux
    @grouped_skills = @user_skills.reject { |us| ["Contrôle", "Sens", "Altération", "Résistance Corporelle"].include?(us.skill.name) }
                                  .group_by { |us| us.skill.carac&.name }
  
    @jedi_skills = @user_skills.select { |us| ["Contrôle", "Sens", "Altération"].include?(us.skill.name) }
    @corporelle_skill = @user_skills.find { |us| us.skill.name == "Résistance Corporelle" }
  end

  def update_skills
    @user = User.find(params[:id])
  
    params[:user_skills].each do |skill_id, attrs|
      user_skill = @user.user_skills.find_or_initialize_by(skill_id: skill_id)
      user_skill.update(mastery: attrs[:mastery], bonus: attrs[:bonus])
    end
  
    redirect_to user_path(@user), notice: 'Compétences mises à jour !'
  end
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
    user.broadcast_energy_shield_update
    user.broadcast_echani_shield_update
  
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
  end
  
  def update_account
    @user = current_user

    if @user.update(email: params[:user][:email])
      redirect_to settings_user_path(@user), notice: 'Email mis à jour avec succès.'
    else
      redirect_to settings_user_path(@user), alert: "Erreur lors de la mise à jour de l'email: #{@user.errors.full_messages.join(', ')}"
    end
  end

  def update_password
    @user = current_user

    # Vérifier que le mot de passe actuel est correct
    unless @user.valid_password?(params[:user][:current_password])
      redirect_to settings_user_path(@user), alert: 'Le mot de passe actuel est incorrect.'
      return
    end

    # Vérifier que les nouveaux mots de passe correspondent
    if params[:user][:password].blank?
      redirect_to settings_user_path(@user), alert: 'Le nouveau mot de passe ne peut pas être vide.'
      return
    end

    if params[:user][:password] != params[:user][:password_confirmation]
      redirect_to settings_user_path(@user), alert: 'Les mots de passe ne correspondent pas.'
      return
    end

    # Mettre à jour le mot de passe
    if @user.update(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
      # Bypass sign_in pour éviter de déconnecter l'utilisateur
      bypass_sign_in(@user)
      redirect_to settings_user_path(@user), notice: 'Mot de passe mis à jour avec succès.'
    else
      redirect_to settings_user_path(@user), alert: "Erreur lors de la mise à jour du mot de passe: #{@user.errors.full_messages.join(', ')}"
    end
  end

  def update_settings
    @user = current_user
  
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

    # Gestion de l'attribut "Junkie"
    if params[:user].key?(:junkie)
      @user.update(junkie: params[:user][:junkie] == "1")
      Rails.logger.debug "✅ 'Junkie' #{@user.junkie ? 'activé' : 'désactivé'} pour #{@user.username}."
    end
  
    # Gestion de la "Chance du Contrebandier"
    if params[:user].key?(:luck)
      @user.update(luck: params[:user][:luck] == "1")
      Rails.logger.debug "✅ 'Chance du Contrebandier' #{@user.luck ? 'activée' : 'désactivée'} pour #{@user.username}."
    end

    # Gestion de la "Robustesse"
    if params[:user].key?(:robustesse)
      @user.update(robustesse: params[:user][:robustesse] == "1")
      Rails.logger.debug "✅ 'Robustesse' #{@user.robustesse ? 'activée' : 'désactivée'} pour #{@user.username}."
    end
  
    redirect_to settings_user_path(@user), notice: 'Réglages mis à jour avec succès.'
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
    render :medipack
  end

  def healobjects
    @heal_objects = InventoryObject.where(category: 'soins').where(rarity: ['Commun', 'Unco'])
  end

  def medipack
    @users = User.joins(:group).where(groups: { name: "PJ" }).order(:username).to_a
    @users.delete(current_user)
    @users.unshift(current_user)

    @pets = @users.map(&:pet).compact

    @user_inventory_objects = current_user.user_inventory_objects.includes(:inventory_object)
  end

  def heal_player
    Rails.logger.debug "➡️ Début de l'action heal_player"
  
    begin
      Rails.logger.debug "Params reçus: #{params.inspect}"
  
      # Identifier si la cible est un joueur ou un pet
      target = if params[:target_type] == "pet"
                 Pet.find(params[:target_id])
               else
                 User.find(params[:target_id])
               end
  
      Rails.logger.debug "🎯 Cible chargée: #{target.inspect}"
  
      # Charger l'objet de soin
      heal_item = current_user.user_inventory_objects.find_by(inventory_object_id: params[:item_id])
      inventory_object = heal_item&.inventory_object || InventoryObject.find_by(id: params[:item_id])
      Rails.logger.debug "📦 Objet de soin : #{inventory_object.inspect}"
  
      if inventory_object.nil?
        Rails.logger.debug "❌ Objet de soin introuvable."
        render json: { error: "Objet de soin introuvable." }, status: :unprocessable_entity
        return
      end
  
      # Vérifier la validité et la quantité de l'objet de soin
      if heal_item.nil? || heal_item.quantity <= 0
        Rails.logger.debug "❌ Objet de soin invalide ou quantité insuffisante."
        render json: { error: "Objet de soin invalide ou quantité insuffisante." }, status: :unprocessable_entity
        return
      end
  
      # Vérifier si la cible est déjà au max de ses PV
      if target.hp_current >= target.hp_max
        render json: { error_message: "#{target.name} a déjà tous ses PV !" }, status: :unprocessable_entity
        return
      end
  
      # Application des effets
      healed_points, new_status = inventory_object.apply_effects(target, current_user)
      Rails.logger.debug "❤️ Points de soin : #{healed_points}, Nouveau statut : #{new_status.inspect}"
  
      if healed_points <= 0 && new_status.nil?
        render json: { error_message: "Cet objet ne peut pas être utilisé dans ce contexte." }, status: :unprocessable_entity
        return
      end
  
      new_hp = [target.hp_current + healed_points, target.hp_max].min
      Rails.logger.debug "🔄 Nouveau PV : #{new_hp}"
  
      # Transaction pour appliquer les soins
      ActiveRecord::Base.transaction do
        Rails.logger.debug "🔄 Début de la transaction"
  
        # Mettre à jour la quantité sauf pour "Homéopathie"
        if inventory_object.name != "Homéopathie" && healed_points > 0
          heal_item.quantity -= 1
          heal_item.save!
          Rails.logger.debug "🩹 Quantité mise à jour : #{heal_item.quantity}"
        end
  
        # Mise à jour des PV
        target.update!(hp_current: new_hp)
  
        # Diffuser la mise à jour des PV
        if target.is_a?(User)
          target.broadcast_hp_update
        end
  
        Rails.logger.debug "👤 PV mis à jour"
  
        # Mise à jour du statut si nécessaire
        if new_status
          target.set_status(new_status)
  
          if target.is_a?(User)
            target.broadcast_status_update
          end
  
          Rails.logger.debug "🔄 Statut mis à jour : #{new_status}"
        end
      end
  
      Rails.logger.debug "✅ Transaction effectuée avec succès"
  
      # Réponse JSON
      render json: {
        target_id: target.id,
        new_hp: new_hp,
        item_quantity: heal_item&.quantity || "illimité",
        healed_points: healed_points,
        target_name: target.name,
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

  def equip_patch
    patch_id = params[:patch_id]
    inventory_object = InventoryObject.find_by(id: patch_id)

    unless current_user.user_inventory_objects.exists?(inventory_object_id: patch_id)
      return render json: { error: "Patch non disponible." }, status: :unprocessable_entity
    end

    current_user.equip_patch(patch_id)
    render json: { success: "Patch équipé : #{inventory_object.name}." }
  end

  def unequip_patch
    if current_user.patch.present?
      current_user.unequip_patch
      render json: { success: "Patch déséquipé." }
    else
      render json: { error: "Aucun patch équipé." }, status: :unprocessable_entity
    end
  end
  
  def use_patch
    if current_user.patch.blank?
      return render json: { error: "Aucun patch actuellement équipé." }, status: :unprocessable_entity
    end
  
    equipped_patch = current_user.equipped_patch
    inventory_object = current_user.user_inventory_objects.find_by(inventory_object_id: equipped_patch.id)
  
    ActiveRecord::Base.transaction do
      case equipped_patch.name
      when "Poisipatch"
        unless current_user.statuses.exists?(name: "Empoisonné")
          return render json: { error: "Le Poisipatch ne peut être utilisé que si vous êtes empoisonné." }, status: :unprocessable_entity
        end
        current_user.set_status("En forme")
  
      when "Traumapatch"
        healed_points = rand(1..6)
        new_hp = [current_user.hp_current + healed_points, current_user.hp_max].min
        current_user.update!(hp_current: new_hp)
  
      when "Stimpatch"
        unless current_user.statuses.exists?(name: "Sonné")
          return render json: { error: "Le Stimpatch ne peut être utilisé que si vous êtes sonné." }, status: :unprocessable_entity
        end
        current_user.set_status("En forme")
      end
  
      inventory_object&.decrement!(:quantity)
      current_user.update!(patch: nil)
    end
  
    render json: { success: "Patch « #{equipped_patch.name} » utilisé avec succès." }
  
  rescue => e
    Rails.logger.error "Erreur lors de l'utilisation du patch : #{e.message}"
    render json: { error: "Erreur lors de l'utilisation du patch." }, status: :internal_server_error
  end

  def equip_implant
    implant_id = params[:implant_id]
    implant = InventoryObject.find_by(id: implant_id)

    unless current_user.user_inventory_objects.exists?(inventory_object_id: implant_id)
      return render json: { error: "Implant non disponible." }, status: :unprocessable_entity
    end

    current_user.equip_implant(implant_id)
    current_user.apply_implant_effects

    render json: { success: "Implant équipé : #{implant.name}." }
  end

  def unequip_implant
    if current_user.active_implant_object
      current_user.remove_implant_effects
      current_user.update!(active_implant: nil)
      render json: { success: "Implant déséquipé." }
    else
      render json: { error: "Aucun implant équipé." }, status: :unprocessable_entity
    end
  end

  def equip_injection
    injection_id = params[:injection_id]
    injection = InventoryObject.find_by(id: injection_id)

    unless current_user.user_inventory_objects.exists?(inventory_object_id: injection_id)
      return render json: { error: "Injection non disponible." }, status: :unprocessable_entity
    end

    current_user.equip_injection(injection_id)
    current_user.decrement_inventory!(injection_id)
    current_user.apply_injection_effects

    unless %w[Injection de trinitine Injection de bio-rage].include?(injection.name) || current_user.junkie
      current_user.decrement!(:hp_current, 2)
    end

    render json: { success: "Injection active : #{injection.name}." }
  end

  def deactivate_injection
    if current_user.active_injection_object
      current_user.remove_injection_effects
      current_user.update!(active_injection: nil)
      render json: { success: "Injection terminée." }
    else
      render json: { error: "Aucune injection active." }, status: :unprocessable_entity
    end
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
    redirect_to user_path(@user, anchor: "inventorySection")
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
    head :ok
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
  
    head :ok
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
  
  def update
    @user = User.find(params[:id])
    
    if @user == current_user && @user.update(user_params)
      respond_to do |format|
        format.html { redirect_to @user, notice: "Profil mis à jour avec succès." }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { render :show }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end

  def update_info
    @user = current_user
    field = params[:user].keys.first
    value = params[:user][field]

    if @user.update(field => value)
      render json: { success: true, value: value }
    else
      render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_entity
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
      :junkie,
      :luck,
      :medicine_mastery,
      :medicine_bonus,
      :res_corp_mastery,
      :res_corp_bonus,
      :reparation_mastery,
      :reparation_bonus,
      :active_injection,
      :active_implant,
      :sex,
      :age,
      :height,
      :weight
    )
  end
  
  def set_user
    @user = User.find(params[:id])
  end
end
