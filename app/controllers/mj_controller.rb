class MjController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_mj

  def roll_dice(number_of_dice, sides = 6)
    results = Array.new(number_of_dice) { rand(1..sides) }
    Rails.logger.debug "Jet : #{results.inspect}"
    results.sum
  end

  def infliger_degats
    case params[:type]
    when 'pets'
      @pets = Pet.where(id: User.where.not(pet_id: nil).pluck(:pet_id))
    when 'spheros'
      @spheros = Sphero.where(active: true) # Sélectionne uniquement les sphéro-droïdes actifs
    else
      @users = User.where(group_id: Group.find_by(name: "PJ").id)
    end
  end

  def apply_damage
    Rails.logger.debug "Paramètres reçus : #{params.inspect}"
    user = User.find(damage_params[:user_id])
    damage = damage_params[:damage].to_i
    attack_type = damage_params[:attack_type] # "energy", "physical", "ignore_defense"
    Rails.logger.debug "Type d'attaque : #{attack_type}"
  
    # Récupération de la compétence "Résistance corporelle"
    resistance_skill = user.user_skills.joins(:skill).find_by(skills: { name: "Résistance Corporelle" })
    resistance_bonus = if resistance_skill.nil?
                        Rails.logger.warn "⚠️ Compétence 'Résistance corporelle' introuvable pour l'utilisateur #{user.id}."
                        0
                      else
                        resistance_mastery = resistance_skill.mastery || 0
                        roll_dice(resistance_mastery, 6) + (resistance_skill.bonus || 0)
                      end
    Rails.logger.debug "🎲 Bonus total de résistance corporelle : #{resistance_bonus}"
  
    message = ""
  
    case attack_type
    when "energy"
      if user.shield_state && user.shield_current > 0
        # Dégâts au bouclier énergétique
        new_shield_value = [user.shield_current - damage, 0].max
        user.update(
          shield_current: new_shield_value,
          shield_state: new_shield_value > 0
        )
        user.broadcast_energy_shield_update
        message = "Bouclier d'énergie a pris #{damage} dégâts."
    
        # turbo_stream_action seulement si le bouclier tombe à zéro
        turbo_stream_action(user, "energy") if new_shield_value == 0
      else
        # Calcul des dégâts résiduels pour les PV
        actual_damage = calculate_damage(damage, resistance_bonus)
        new_hp_value = user.hp_current - actual_damage
        new_hp_value = [new_hp_value, -10].max
        user.update(hp_current: new_hp_value)
        user.broadcast_hp_update

        message = "Le joueur a pris #{actual_damage} dégâts après résistance corporelle."
      end
  
      # Appel à la gestion des patchs après application des dégâts
      patch_message = handle_patch_activation(user, damage)
      message += " #{patch_message}" if patch_message
  
    when "physical"
      if user.echani_shield_state && user.echani_shield_current > 0
        # Dégâts au bouclier Échani
        new_shield_value = [user.echani_shield_current - damage, 0].max
        user.update(
          echani_shield_current: new_shield_value,
          echani_shield_state: new_shield_value > 0
        )
        user.broadcast_echani_shield_update

        if new_shield_value == 0
          turbo_stream_action(user, "echani")
        end
        
        message = "Bouclier Échani a pris #{damage} dégâts."
      else
        # Calcul des dégâts résiduels pour les PV
        actual_damage = calculate_damage(damage, resistance_bonus)
        new_hp_value = user.hp_current - actual_damage
        new_hp_value = [new_hp_value, -10].max
        user.update(hp_current: new_hp_value)
        user.broadcast_hp_update
        message = "Le joueur a pris #{actual_damage} dégâts après résistance corporelle."
      end
  
      # Appel à la gestion des patchs après application des dégâts
      patch_message = handle_patch_activation(user, damage)
      message += " #{patch_message}" if patch_message
  
    when "ignore_defense"
      # Dégâts ignorants la défense et les boucliers, allant directement aux PV
      new_hp_value = user.hp_current - damage
      new_hp_value = [new_hp_value, -10].max
      user.update(hp_current: new_hp_value)
      user.broadcast_hp_update
      message = "Le joueur a pris #{damage} dégâts directs, ignorants boucliers et résistance."
    
      # Appel à la gestion des patchs après application des dégâts
      patch_message = handle_patch_activation(user, damage)
      message += " #{patch_message}" if patch_message
  
    else
      # Type d'attaque non valide
      render json: { success: false, message: "Type d'attaque invalide." }, status: :unprocessable_entity
      return
    end
  
    # Retourner les résultats
    render json: { success: true, hp_current: user.hp_current, shield_current: user.shield_current, echani_shield_current: user.echani_shield_current, message: message }
  end
  
  def apply_damage_pets
    Rails.logger.debug "📌 Paramètres reçus : #{params.inspect}"
    pet = Pet.find(params[:pet_id])
    damage = params[:damage].to_i
    attack_type = params[:attack_type] # "energy", "physical", "ignore_defense"
  
    Rails.logger.debug "⚔️ Type d'attaque : #{attack_type}"
  
    # Calcul du bonus de résistance des pets
    resistance_bonus = pet.calculate_resistance_bonus
    Rails.logger.debug "🛡️ Résistance corporelle du pet : #{resistance_bonus}"
  
    message = ""
  
    case attack_type
    when "energy"
      if pet.shield_max > 0 && pet.shield_current > 0
        # Attaque sur le bouclier énergétique
        new_shield_value = [pet.shield_current - damage, 0].max
        pet.update(shield_current: new_shield_value)
  
        Rails.logger.debug "🛡️ Bouclier énergétique a absorbé #{damage} dégâts."
        message = "Le pet #{pet.name} a perdu #{damage} points de bouclier."
  
        if new_shield_value == 0
          Rails.logger.debug "❗ Bouclier énergétique détruit."
        end
      else
        actual_damage = [damage - resistance_bonus, 1].max
        new_hp_value = [pet.hp_current - actual_damage, -10].max
        pet.update(hp_current: new_hp_value)
        
        Rails.logger.debug "💥 Le pet #{pet.name} a pris #{actual_damage} dégâts énergétiques."
        message = "Le pet #{pet.name} a subi #{actual_damage} dégâts énergétiques."
      end
  
    when "physical"
      # Les dégâts physiques contournent le bouclier et vont directement aux PV
      actual_damage = [damage - resistance_bonus, 1].max
      new_hp_value = [pet.hp_current - actual_damage, -10].max
      pet.update(hp_current: new_hp_value)
  
      Rails.logger.debug "🩸 Le pet #{pet.name} a pris #{actual_damage} dégâts physiques après résistance."
      message = "Le pet #{pet.name} a subi #{actual_damage} dégâts physiques après résistance."
  
    when "ignore_defense"
      # Dégâts ignorants la défense et les boucliers, allant directement aux PV
      new_hp_value = [pet.hp_current - damage, -10].max
      pet.update(hp_current: new_hp_value)
  
      Rails.logger.debug "💀 Le pet #{pet.name} a pris #{damage} dégâts directs, ignorants toute défense."
      message = "Le pet #{pet.name} a subi #{damage} dégâts directs, ignorants la résistance et les boucliers."
  
    else
      Rails.logger.error "⚠️ Type d'attaque invalide : #{attack_type}"
      render json: { success: false, message: "Type d'attaque invalide." }, status: :unprocessable_entity
      return
    end
  
    # Retourner les résultats
    render json: {
      success: true,
      hp_current: pet.hp_current,
      shield_current: pet.shield_current,
      message: message
    }
  end

  def apply_damage_spheros
    sphero = Sphero.find(params[:sphero_id])
    damage = params[:damage].to_i
    attack_type = params[:attack_type]
  
    Rails.logger.debug "💥 Attaque reçue : #{damage} dégâts de type #{attack_type} sur #{sphero.name}"
  
    # 🔹 Étape 1 : Gestion du bouclier
    if sphero.shield_current > 0
      shield_damage = [damage, sphero.shield_current].min
      sphero.update!(shield_current: sphero.shield_current - shield_damage)
  
      Rails.logger.debug "🛡️ Bouclier absorbé #{shield_damage} dégâts. Nouveau bouclier : #{sphero.shield_current}"
  
      return render json: {
        success: true,
        hp_current: sphero.hp_current,
        shield_current: sphero.shield_current,
        message: "Le sphéro-droïde #{sphero.name} a perdu #{shield_damage} points de bouclier."
      }
    end
  
    # 🔹 Étape 2 : Dégâts sur les HP (si bouclier épuisé)
    if sphero.shield_current == 0
      if attack_type == "physical"
        resistance_skill = sphero.sphero_skills.joins(:skill).find_by(skills: { name: "Résistance Corporelle" })
        
        if resistance_skill.nil?
          Rails.logger.warn "⚠️ Compétence 'Résistance Corporelle' introuvable pour le sphéro-droïde #{sphero.id}."
          resistance_bonus = 0
        else
          resistance_mastery = resistance_skill.mastery || 0
          resistance_bonus = (1..resistance_mastery).map { rand(1..6) }.sum + (resistance_skill.bonus || 0)
        end
      
        Rails.logger.debug "🎲 Jet de Résistance Corporelle : #{resistance_bonus}"
        damage = [damage - resistance_bonus, 0].max # Réduction des dégâts
      end
  
      new_hp_value = [sphero.hp_current - damage, 0].max
      sphero.update!(hp_current: new_hp_value)
  
      Rails.logger.debug "💥 Dégâts appliqués : #{damage} PV sur #{sphero.name}"
  
      return render json: {
        success: true,
        hp_current: sphero.hp_current,
        shield_current: sphero.shield_current,
        message: "Le sphéro-droïde #{sphero.name} a perdu #{damage} PV."
      }
    end
  end

  def handle_patch_activation(user, damage)
    return nil unless user.patch.present?
  
    equipped_patch = user.equipped_patch
  
    case equipped_patch.name
    when "Vitapatch"
      # Activation si les PV passent sous 0
      if user.hp_current < 0
        ActiveRecord::Base.transaction do
          user.update!(hp_current: 0, patch: nil)
          inventory_object = user.user_inventory_objects.find_by(inventory_object_id: equipped_patch.id)
          inventory_object.decrement!(:quantity) if inventory_object.present?
        end
  
        user.broadcast_hp_update
        user.broadcast_replace_to(
          "notifications_#{user.id}",
          target: "notification_frame",
          partial: "pages/notification",
          locals: { message: "PATCH UTILISÉ : #{equipped_patch.name} activé automatiquement !" }
        )
        return "Vitapatch activé automatiquement ! Le joueur revient à 0 PV."
      end
  
    when "Traumapatch"
      # Activation si des dégâts > 1 ont été infligés
      if damage > 1
        healing = rand(1..6) # Jet de dés pour soins
        ActiveRecord::Base.transaction do
          new_hp_value = [user.hp_current + healing, user.hp_max].min
          user.update!(hp_current: new_hp_value, patch: nil)
          inventory_object = user.user_inventory_objects.find_by(inventory_object_id: equipped_patch.id)
          inventory_object.decrement!(:quantity) if inventory_object.present?
        end
  
        user.broadcast_hp_update
        user.broadcast_replace_to(
          "notifications_#{user.id}",
          target: "notification_frame",
          partial: "pages/notification",
          locals: { message: "PATCH UTILISÉ : #{equipped_patch.name} activé automatiquement !" }
        )
        return "Traumapatch activé automatiquement ! Le joueur regagne #{healing} PV."
      end
    end
  
    nil
  end

  def fixer_pv_max
    @users = User.where(group_id: Group.find_by(name: "PJ").id).includes(:user_caracs => :carac)
    @carac_names = Carac.pluck(:name)
  end

  def update_pv_max
    user_ids = (update_params[:pv_max]&.keys || []) +
               (update_params[:shield_max]&.keys || []) +
               (update_params[:echani_shield_max]&.keys || [])
    users = User.where(id: user_ids.uniq)
    users_by_id = users.index_by(&:id)
  
    update_params[:pv_max]&.each do |user_id, hp_max_value|
      user = users_by_id[user_id.to_i]
      if user&.update(hp_max: hp_max_value.to_i)
        user.broadcast_hp_update
        Rails.logger.debug "Updated HP Max for user ##{user.id} to #{user.hp_max}"
      end
    end
  
    update_params[:shield_max]&.each do |user_id, shield_max_value|
      user = users_by_id[user_id.to_i]
      if user&.update(shield_max: shield_max_value.to_i)
        user.update(shield_current: shield_max_value.to_i) if user.shield_current.nil? || user.shield_current < shield_max_value.to_i
        user.broadcast_energy_shield_update
        Rails.logger.debug "Updated Shield Max for user ##{user.id} to #{user.shield_max}"
      end
    end
  
    update_params[:echani_shield_max]&.each do |user_id, echani_shield_max_value|
      user = users_by_id[user_id.to_i]
      if user&.update(echani_shield_max: echani_shield_max_value.to_i)
        user.update(echani_shield_current: echani_shield_max_value.to_i) if user.echani_shield_current.nil? || user.echani_shield_current < echani_shield_max_value.to_i
        user.broadcast_echani_shield_update
        Rails.logger.debug "Updated Echani Shield Max for user ##{user.id} to #{user.echani_shield_max}"
      end
    end
  
    redirect_to fixer_pv_max_path, notice: "PV Max et Boucliers mis à jour dynamiquement"
  end

  def update_user_caracs
    user = User.find(params[:id])
    params[:user_caracs]&.each do |carac_id, values|
      user_carac = user.user_caracs.find_by(carac_id: carac_id)
      if user_carac
        user_carac.update(
          mastery: values[:mastery].to_i,
          bonus: values[:bonus].to_i
        )
      end
    end
    redirect_back fallback_location: fixer_pv_max_path, notice: "Caractéristiques mises à jour pour #{user.username}"
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

    xp_updates.each do |update|
      user = User.find(update[:id])
      user.broadcast_replace_to(
        "xp_updates_#{user.id}",
        target: "user_#{user.id}_xp_frame",
        partial: "pages/xp_update",
        locals: { user: user }
      )
    end
  
    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_to donner_xp_path, notice: "XP mis à jour !" }
    end
  end

  def fixer_statut
    @users = User.where(group: Group.find_by(name: "PJ"))
    @pets = Pet.where(id: User.where.not(pet_id: nil).pluck(:pet_id))
    @statuses = Status.all
  end

  def fixer_statut_pets
    params[:status].each do |pet_id, status_id|
      pet = Pet.find_by(id: pet_id)
      if pet
        previous_status = pet.status_id
        pet.update(status_id: status_id)
  
        if previous_status == Status.find_by(name: "Mort")&.id && status_id != previous_status
          pet.update(hp_current: [pet.hp_current, -9].max)
          Rails.logger.debug "🔥 Statut Mort retiré, PV ajustés à #{pet.hp_current}"
        end
      end
    end
    redirect_to mj_fixer_statut_path(type: 'pets'), notice: "Statuts des pets mis à jour avec succès."
  end

  def update_statut
    params[:status].each do |user_id, status_id|
      user = User.find(user_id)
      new_status = Status.find(status_id)
  
      # Gestion des patchs automatiques
      if user.patch.present?
        equipped_patch = user.equipped_patch
  
        if equipped_patch.name == "Stimpatch" && new_status.name == "Sonné"
          use_patch_automatically(user, "Sonné")
          next
        elsif equipped_patch.name == "Poisipatch" && new_status.name == "Empoisonné"
          use_patch_automatically(user, "Empoisonné")
          next
        end
      end
  
      # Appliquer le statut normalement
      user.statuses = [new_status]
      user.broadcast_status_update
    end
  
    redirect_to fixer_statut_path, notice: "Statuts mis à jour avec succès."
  end

  def donner_objet
    @users = User.joins(:group).where(groups: { name: "PJ" })
    @categories = InventoryObject.distinct.pluck(:category).map(&:downcase).uniq.sort
    @objects = InventoryObject.select(:id, :name, :category).map do |obj|
      { id: obj.id, name: obj.name, category: obj.category.downcase }
    end
  
    Rails.logger.debug "Catégories disponibles : #{@categories}"
  end

  def update_objet
    user_id = params[:user_id]
    object_id = params[:object_id]
    quantity = params[:quantity].to_i
  
    user = User.find(user_id)
    object = InventoryObject.find(object_id)
  
    user_inventory_object = user.user_inventory_objects.find_or_initialize_by(inventory_object_id: object.id)
    user_inventory_object.quantity ||= 0
    user_inventory_object.quantity += quantity
    user_inventory_object.save!
  
    Rails.logger.info "✅ Objet #{object.name} (x#{quantity}) donné à #{user.username}."
  
    respond_to do |format|
      format.json { render json: { success: true, message: "Objet #{object.name} (x#{quantity}) donné avec succès à #{user.username}." } }
    end
  rescue ActiveRecord::RecordNotFound => e
    respond_to do |format|
      format.json { render json: { success: false, error: "Erreur : #{e.message}" }, status: :unprocessable_entity }
    end
  end

  def fix_pets
    if request.patch?
      @pet = Pet.find(params[:id])
      attribute = params[:attribute]
      value = params[:value].to_i

      if @pet.update(attribute => value)
        flash[:success] = "L'attribut #{attribute.humanize} de #{@pet.name} a été mis à jour avec succès !"
      else
        flash[:error] = "Échec de la mise à jour de #{@pet.name}."
      end
      redirect_to fix_pets_path
    else
      @pets = Pet.includes(:user) # Charge tous les pets pour le GET
    end
  end

  def send_pet_action_points
    pj_group = Group.find_by(name: "PJ")

    if pj_group.nil?
      redirect_to mj_dashboard_path, alert: "Le groupe des joueurs (PJ) n'existe pas." and return
    end

    # Ajouter 5 points d'action aux utilisateurs du groupe "PJ", sans dépasser 10
    pj_users = User.where(group_id: pj_group.id)
    pj_users.each do |user|
      user.update!(pet_action_points: [user.pet_action_points + 5, 10].min)
    end

    redirect_to fix_pets_path, notice: "5 points d'action ont été attribués aux joueurs (maximum 10 points par utilisateur)."
  end

  def reset_health
    # Soigner tous les joueurs du groupe PJ qui ont des PV inférieurs à leur maximum
    players = User.where(group: Group.find_by(name: "PJ"))
    players.each do |player|
      player.update(hp_current: player.hp_max) if player.hp_current < player.hp_max
    end

    # Soigner tous les pets sauf ceux qui sont morts ou qui ont déjà des PV supérieurs ou égaux à leur maximum
    pets = Pet.where("hp_current > ?", -10)
    pets.each do |pet|
      pet.update(hp_current: pet.hp_max) if pet.hp_current < pet.hp_max
    end

    flash[:success] = "Tous les joueurs et leurs familiers blessés ont été soignés !"
    redirect_to infliger_degats_path
  end

  def apply_hp_bonus
    bonus = params[:hp_bonus][:bonus].to_i
    users = User.where(group: Group.find_by(name: "PJ"))
  
    User.transaction do
      users.find_each do |user|
        user.update!(hp_current: user.hp_max + bonus)
        user.broadcast_hp_update
      end
    end
  
    flash[:success] = "Bonus temporaire de #{bonus} PV attribué à tous les joueurs."
    redirect_to mj_dashboard_path
  end

  def sphero
    @sphero = Sphero.new
    @players = User.where(group: Group.find_by(name: "PJ"))
  
    if @players.empty?
      flash[:alert] = "Aucun joueur trouvé dans le groupe PJ."
      redirect_to mj_sphero_path and return
    end
  end
  
  def create_sphero
    @sphero = Sphero.new(sphero_params)
    @players = User.where(group: Group.find_by(name: "PJ"))
  
    if @sphero.save
      redirect_to mj_sphero_path, notice: "Sphéro-Droïde créé avec succès."
    else
      render :new_sphero
    end
  end
  
  def fixer_points
    @users = User.joins(:group).where(groups: { name: "PJ" })
  end

  def update_points
    user = User.find(params[:id])
    
    case params[:type]
    when 'force'
      new_value = params[:value].to_i
      new_value = [[-5, new_value].max, 5].min # Limiter entre -5 et 5
      user.update(dark_side_points: new_value)
    when 'cyber'
      new_value = params[:value].to_i
      new_value = [[0, new_value].max, 3].min # Limiter entre 0 et 3
      user.update(cyber_points: new_value)
    end

    redirect_to fixer_points_path
  end

  def reset_points
    user = User.find(params[:id])
    user.update(dark_side_points: 0, cyber_points: 0)
    redirect_to fixer_points_path
  end

  def vaisseaux
    @ships = Ship.joins(:group).where(groups: { name: "PJ" }).includes(:ships_skills, :ship_weapons)
    @skills = Skill.all
  end

  def update_ship
    @ship = Ship.find(params[:id])
    
    if @ship.update(ship_basic_params)
      redirect_to mj_vaisseaux_path, notice: "Informations du vaisseau #{@ship.name} mises à jour avec succès."
    else
      redirect_to mj_vaisseaux_path, alert: "Erreur lors de la mise à jour : #{@ship.errors.full_messages.join(', ')}"
    end
  end

  def update_ship_stats
    @ship = Ship.find(params[:id])
    
    if @ship.update(ship_stats_params)
      redirect_to mj_vaisseaux_path, notice: "Statistiques du vaisseau #{@ship.name} mises à jour avec succès."
    else
      redirect_to mj_vaisseaux_path, alert: "Erreur lors de la mise à jour : #{@ship.errors.full_messages.join(', ')}"
    end
  end

  def update_ship_skills
    @ship = Ship.find(params[:id])
    
    if params[:ship_skills].present?
      params[:ship_skills].each do |skill_id, values|
        ship_skill = @ship.ships_skills.find_by(skill_id: skill_id)
        if ship_skill
          ship_skill.update(
            mastery: values[:mastery].to_i,
            bonus: values[:bonus].to_i
          )
        elsif values[:mastery].to_i > 0 || values[:bonus].to_i > 0
          # Créer une nouvelle compétence si elle n'existe pas et a des valeurs
          @ship.ships_skills.create(
            skill_id: skill_id,
            mastery: values[:mastery].to_i,
            bonus: values[:bonus].to_i
          )
        end
      end
    end
    
    redirect_to mj_vaisseaux_path, notice: "Compétences du vaisseau #{@ship.name} mises à jour avec succès."
  end

  def update_ship_weapons
    @ship = Ship.find(params[:id])
    
    if params[:ship_weapons].present?
      params[:ship_weapons].each do |weapon_id, values|
        weapon = @ship.ship_weapons.find_by(id: weapon_id)
        if weapon
          weapon.update(
            damage_mastery: values[:damage_mastery].to_i,
            damage_bonus: values[:damage_bonus].to_i,
            aim_mastery: values[:aim_mastery].to_i,
            aim_bonus: values[:aim_bonus].to_i,
            quantity_current: values[:quantity_current].present? ? values[:quantity_current].to_i : weapon.quantity_current,
            quantity_max: values[:quantity_max].present? ? values[:quantity_max].to_i : weapon.quantity_max
          )
        end
      end
    end
    
    redirect_to mj_vaisseaux_path, notice: "Armes du vaisseau #{@ship.name} mises à jour avec succès."
  end

  def update_ship_status
    @ship = Ship.find(params[:id])
    
    if @ship.update(ship_status_params)
      redirect_to mj_vaisseaux_path, notice: "Statuts du vaisseau #{@ship.name} mis à jour avec succès."
    else
      redirect_to mj_vaisseaux_path, alert: "Erreur lors de la mise à jour : #{@ship.errors.full_messages.join(', ')}"
    end
  end
  
  private
  
  def sphero_params
    params.require(:sphero).permit(:name, :category, :quality, :user_id)
  end
  
  def calculate_damage(damage, resistance_bonus)
    if resistance_bonus >= damage * 2
      Rails.logger.debug "🎯 Résistance corporelle annule complètement les dégâts."
      0
    elsif resistance_bonus >= damage
      Rails.logger.debug "⚡ Résistance corporelle réduit les dégâts à un minimum de 1 PV."
      1
    else
      Rails.logger.debug "🔥 Dégâts normaux après résistance corporelle."
      damage - resistance_bonus
    end
  end
  
  def xp_params
    params.require(:xp).permit(:xp, :user_id, :give_to_all)
  end

  def authorize_mj
    unless current_user.group.name == "MJ"
      redirect_to root_path, alert: "Accès refusé."
    end
  end

  def damage_params
    params.permit(:user_id, :damage, :attack_type, :authenticity_token)
  end

  def update_params
    params.except(:authenticity_token, :commit).permit(
      pv_max: {},
      shield_max: {},
      echani_shield_max: {}
    ).to_h
  end

  def use_patch_automatically(user, status_name)
    equipped_patch = user.equipped_patch
    inventory_object = user.user_inventory_objects.find_by(inventory_object_id: equipped_patch.id)
  
    ActiveRecord::Base.transaction do
      # Réduire la quantité du patch et déséquiper
      inventory_object.decrement!(:quantity) if inventory_object.present?
      user.update!(patch: nil)
  
      # Remettre le statut à "En forme"
      user.set_status("En forme")
    end
  
    # Notification Turbo Streams
    user.broadcast_replace_to(
      "notifications_#{user.id}",
      target: "notification_frame",
      partial: "pages/notification",
      locals: { message: "PATCH UTILISÉ : #{equipped_patch.name} activé automatiquement !" }
    )
  
    Rails.logger.info "✔️ Patch automatique activé : #{equipped_patch.name} pour #{user.username}, statut '#{status_name}' annulé."
  end

  def ship_basic_params
    params.require(:ship).permit(:name, :brand, :model, :description, :price)
  end

  def ship_stats_params
    params.require(:ship).permit(
      :size, :max_passengers, :min_crew, :hp_max, :hp_current, 
      :hyperdrive_rating, :backup_hyperdrive, :astromech_droids,
      :thruster_level, :hull_level, :circuits_level, :shield_system_level,
      :torpilles_count, :missiles_count
    )
  end

  def ship_status_params
    params.require(:ship).permit(
      :thrusters_damaged, :hyperdrive_damaged, :depressurized, 
      :weapons_disabled, :sensors_damaged, :life_support_damaged,
      :shields_down, :power_core_damaged
    )
  end
end
