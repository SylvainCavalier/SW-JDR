class ShipsController < ApplicationController
  before_action :set_ship, only: [:show, :edit, :update, :destroy, :set_active, :dock, :undock, :inventory, :improve, :upgrade, :upgrade_sensor, :upgrade_hp_max, :buy_weapon, :install_weapon, :uninstall_weapon, :sell_weapon, :buy_launcher, :buy_ammunition, :buy_turret, :install_turret, :uninstall_turret, :sell_turret, :upgrade_weapon_damage, :upgrade_weapon_aim, :buy_special_equipment, :install_special_equipment, :uninstall_special_equipment, :sell_special_equipment, :crew, :assign_crew, :remove_crew_member, :repair, :use_repair_kit, :deploy_astromech_droid]
  before_action :authenticate_user!

  def index
    @ships = current_user.group.ships.order(active: :desc, name: :asc)
  end

  def show
    @skills = @ship.ships_skills.includes(:skill)
    @objects = @ship.ship_objects
    @child_ships = @ship.child_ships
  end

  def new
    @ship = Ship.new
  end

  def create
    @ship = Ship.new(ship_params)
    @ship.group = current_user.group
    if @ship.save
      update_ship_skills(@ship)
      update_ship_weapons(@ship)
      redirect_to @ship, notice: "Vaisseau créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ship.update(ship_params)
      # Si on ne modifie que le nom ou l'image, pas besoin de mettre à jour les skills/weapons
      if params[:ship].keys == ["name"] || params[:ship].keys == ["image"]
        message = if params[:ship].keys == ["name"]
                    "Nom du vaisseau mis à jour."
                  else
                    "Image du vaisseau mise à jour."
                  end
        redirect_to @ship, notice: message
      else
        # Mise à jour complète (depuis le formulaire d'édition)
        update_ship_skills(@ship)
        @ship.ship_weapons.destroy_all
        update_ship_weapons(@ship)
        redirect_to @ship, notice: "Vaisseau mis à jour."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Si le vaisseau est principal, retirer le statut principal du groupe
    if @ship.active?
      @ship.update(active: false)
    end
    # Détacher tous les enfants (vaisseaux embarqués)
    @ship.child_ships.update_all(parent_ship_id: nil)
    @ship.destroy
    redirect_to ships_path, notice: "Vaisseau supprimé."
  end

  def set_active
    current_user.group.ships.update_all(active: false)
    @ship.update(active: true)
    redirect_to ships_path, notice: "Vaisseau principal changé."
  end

  def dock
    child = Ship.find(params[:child_id])
    parent = Ship.find(params[:parent_id])
    Rails.logger.debug "[DOCK] Tentative d'embarquement : #{child.name} (taille=#{child.size}, scale=#{child.scale}, capacité=#{child.embarked_capacity}) dans #{parent.name} (taille=#{parent.size}, scale=#{parent.scale}, capacité=#{parent.capacity}, utilisé=#{parent.used_capacity})"
    if !child.can_be_embarked?
      Rails.logger.debug "[DOCK] ECHEC : Le vaisseau ne peut pas être embarqué (déjà embarqué ou trop gros). parent_ship_id=#{child.parent_ship_id}, scale=#{child.scale}"
      redirect_to parent, alert: "Ce vaisseau ne peut pas être embarqué (déjà embarqué ou trop gros)."
      return
    end
    unless parent.can_embark_ship?(child)
      Rails.logger.debug "[DOCK] ECHEC : Le parent ne peut pas embarquer ce vaisseau. used_capacity=#{parent.used_capacity}, child_embarked_capacity=#{child.embarked_capacity}, parent_capacity=#{parent.capacity}"
      redirect_to parent, alert: "Le vaisseau #{parent.name} ne peut pas embarquer ce vaisseau (capacité insuffisante ou contraintes de taille)."
      return
    end
    Rails.logger.debug "[DOCK] SUCCES : Embarquement possible."
    child.update(parent_ship: parent)
    redirect_to parent, notice: "Vaisseau amarré dans la soute de #{parent.name}."
  end

  def undock
    @ship.update(parent_ship: nil)
    redirect_to @ship, notice: "Vaisseau désamarré."
  end

  def inventory
    @objects = @ship.ship_objects
  end

  def improve
    @upgrade_types = [:thruster, :hull, :circuits, :shield_system]
    @sensor_skills = ["Senseurs passifs", "Senseurs détection", "Senseurs recherche", "Senseurs focalisation"]
    @user_credits = current_user.credits
    
    # Configuration pour les senseurs
    @sensor_config = {
      name: "Senseurs",
      description: "Améliore les senseurs du vaisseau",
      image: "ships/Senseurs.png"
    }
    
    # Configuration pour les systèmes de survie
    @survival_config = {
      name: "Systèmes de survie",
      description: "Améliore les points de vie maximum du vaisseau",
      image: "ships/Survie.png"
    }
    
    # Configuration pour les armes
    @weapon_config = {
      name: "Armement",
      description: "Gérer les armes du vaisseau",
      icon: "fa-solid fa-crosshairs"
    }
    
    # Configuration des armes prédéfinies (exclure les lanceurs et tourelles qui ont leurs propres sections)
    @predefined_weapons = Ship::PREDEFINED_WEAPONS.reject do |name, config|
      name.include?('Lance-') || config[:weapon_type] == 'tourelle'
    end
  end

  def upgrade
    upgrade_type = params[:upgrade_type].to_sym
    
    unless [:thruster, :hull, :circuits, :shield_system].include?(upgrade_type)
      redirect_to improve_ship_path(@ship), alert: "Type d'amélioration invalide."
      return
    end

    unless @ship.next_upgrade_available?(upgrade_type)
      redirect_to improve_ship_path(@ship), alert: "Aucune amélioration disponible pour ce composant."
      return
    end

    upgrade_price = @ship.upgrade_price(upgrade_type)
    
    unless current_user.credits >= upgrade_price
      redirect_to improve_ship_path(@ship), alert: "Crédits insuffisants pour cette amélioration."
      return
    end

    # Récupérer le nom de l'amélioration avant de l'installer
    upgrade_name = @ship.next_upgrade_info(upgrade_type)[:name]
    
    # Effectuer l'amélioration
    @ship.upgrade!(upgrade_type)
    current_user.update!(credits: current_user.credits - upgrade_price)
    
    redirect_to improve_ship_path(@ship), notice: "#{upgrade_name} installée avec succès !"
  end

  def upgrade_sensor
    sensor_skill_name = params[:sensor_skill_name]
    
    unless ["Senseurs passifs", "Senseurs détection", "Senseurs recherche", "Senseurs focalisation"].include?(sensor_skill_name)
      redirect_to improve_ship_path(@ship), alert: "Type de senseur invalide."
      return
    end

    unless @ship.can_upgrade_sensor?(sensor_skill_name, current_user.credits)
      redirect_to improve_ship_path(@ship), alert: "Crédits insuffisants pour cette amélioration."
      return
    end

    upgrade_price = @ship.sensor_upgrade_price(sensor_skill_name)
    next_bonus = @ship.sensor_next_bonus_string(sensor_skill_name)
    
    # Effectuer l'amélioration
    @ship.upgrade_sensor!(sensor_skill_name)
    current_user.update!(credits: current_user.credits - upgrade_price)
    
    redirect_to improve_ship_path(@ship), notice: "#{sensor_skill_name} amélioré à #{next_bonus} !"
  end

  def upgrade_hp_max
    unless @ship.can_upgrade_hp_max?(current_user.credits)
      redirect_to improve_ship_path(@ship), alert: "Crédits insuffisants pour cette amélioration."
      return
    end

    upgrade_price = @ship.hp_max_upgrade_price
    
    # Effectuer l'amélioration
    @ship.upgrade_hp_max!
    current_user.update!(credits: current_user.credits - upgrade_price)
    
    redirect_to improve_ship_path(@ship), notice: "Systèmes de survie améliorés ! HP Max +1"
  end

  def buy_weapon
    weapon_name = params[:weapon_name]
    
    unless Ship::PREDEFINED_WEAPONS.key?(weapon_name)
      render json: { error: "Arme invalide." }, status: :unprocessable_entity
      return
    end

    unless @ship.can_buy_weapon?(weapon_name, current_user.credits)
      render json: { error: "Crédits insuffisants pour cette arme." }, status: :unprocessable_entity
      return
    end

    weapon_price = Ship::PREDEFINED_WEAPONS[weapon_name][:price]
    
    if @ship.buy_weapon!(weapon_name)
      current_user.update!(credits: current_user.credits - weapon_price)
      render json: {
        message: "#{weapon_name} acheté avec succès !",
        weapons_html: render_to_string(
          partial: 'ships/weapon_section',
          formats: [:html],
          locals: { ship: @ship, user_credits: current_user.credits }
        ),
        user_credits: current_user.credits
      }
    else
      render json: { error: "Erreur lors de l'achat de l'arme." }, status: :unprocessable_entity
    end
  end

  def install_weapon
    weapon_id = params[:weapon_id]
    slot = params[:slot]
    
    unless ['main', 'secondary'].include?(slot)
      render json: { error: "Slot d'arme invalide." }, status: :unprocessable_entity
      return
    end

    unless @ship.install_weapon!(weapon_id, slot)
      render json: { error: "Impossible d'installer cette arme." }, status: :unprocessable_entity
      return
    end

    slot_name = slot == 'main' ? 'principale' : 'secondaire'
    render json: {
      message: "Arme installée comme arme #{slot_name} !",
      weapons_html: render_to_string(
        partial: 'ships/weapon_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      )
    }
  end

  def uninstall_weapon
    slot = params[:slot]
    
    unless ['main', 'secondary', 'torpille', 'missile'].include?(slot)
      render json: { error: "Slot d'arme invalide." }, status: :unprocessable_entity
      return
    end

    unless @ship.uninstall_weapon!(slot)
      render json: { error: "Impossible de désinstaller cette arme." }, status: :unprocessable_entity
      return
    end

    slot_name = case slot
    when 'main' then 'principale'
    when 'secondary' then 'secondaire'
    when 'torpille' then 'Lance-Torpilles'
    when 'missile' then 'Lance-Missiles'
    end
    render json: {
      message: "#{slot_name} désinstallé !",
      weapons_html: render_to_string(
        partial: 'ships/weapon_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      )
    }
  end

  def sell_weapon
    weapon_id = params[:weapon_id]
    
    sell_price = @ship.sell_weapon!(weapon_id)
    
    unless sell_price
      render json: { error: "Impossible de vendre cette arme." }, status: :unprocessable_entity
      return
    end

    current_user.update!(credits: current_user.credits + sell_price)
    render json: {
      message: "Arme vendue pour #{sell_price} crédits !",
      weapons_html: render_to_string(
        partial: 'ships/weapon_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      ),
      user_credits: current_user.credits
    }
  end

  def buy_launcher
    launcher_type = params[:launcher_type]
    
    unless ['torpille', 'missile'].include?(launcher_type)
      redirect_to improve_ship_path(@ship), alert: "Type de lanceur invalide."
      return
    end

    unless @ship.can_buy_launcher?(launcher_type, current_user.credits)
      if launcher_type == 'torpille' && !@ship.can_install_torpedo_launcher?
        redirect_to improve_ship_path(@ship), alert: "Ce vaisseau est trop petit pour installer un lance-torpilles."
      else
        redirect_to improve_ship_path(@ship), alert: "Crédits insuffisants ou lanceur déjà installé."
      end
      return
    end

    weapon_price = Ship::PREDEFINED_WEAPONS[launcher_type == 'torpille' ? "Lance-Torpilles à protons" : "Lance-Missiles à concussion"][:price]
    
    if @ship.buy_launcher!(launcher_type)
      current_user.update!(credits: current_user.credits - weapon_price)
      launcher_name = launcher_type == 'torpille' ? "Lance-Torpilles à protons" : "Lance-Missiles à concussion"
      redirect_to improve_ship_path(@ship), notice: "#{launcher_name} acheté et installé avec 3 munitions !"
    else
      redirect_to improve_ship_path(@ship), alert: "Erreur lors de l'achat du lanceur."
    end
  end

  def buy_ammunition
    ammo_type = params[:ammo_type]
    
    unless ['torpille', 'missile'].include?(ammo_type)
      redirect_to improve_ship_path(@ship), alert: "Type de munition invalide."
      return
    end

    unless @ship.can_buy_ammunition?(ammo_type, current_user.credits)
      redirect_to improve_ship_path(@ship), alert: "Crédits insuffisants ou munitions au maximum."
      return
    end

    ammo_price = @ship.ammunition_price(ammo_type)
    
    if @ship.buy_ammunition!(ammo_type)
      current_user.update!(credits: current_user.credits - ammo_price)
      ammo_name = Ship::AMMUNITION_CONFIG[ammo_type][:name]
      redirect_to improve_ship_path(@ship), notice: "#{ammo_name} acheté !"
    else
      redirect_to improve_ship_path(@ship), alert: "Erreur lors de l'achat de munition."
    end
  end

  def buy_turret
    turret_name = params[:turret_name]
    
    unless Ship::PREDEFINED_WEAPONS.key?(turret_name)
      render json: { error: "Tourelle invalide." }, status: :unprocessable_entity
      return
    end

    unless @ship.can_buy_turret?(turret_name, current_user.credits)
      if @ship.max_turrets == 0
        render json: { error: "Ce vaisseau ne peut pas avoir de tourelles." }, status: :unprocessable_entity
      elsif !@ship.can_install_turret?
        render json: { error: "Nombre maximum de tourelles atteint." }, status: :unprocessable_entity
      else
        render json: { error: "Crédits insuffisants pour cette tourelle." }, status: :unprocessable_entity
      end
      return
    end

    turret_price = Ship::PREDEFINED_WEAPONS[turret_name][:price]
    
    if @ship.buy_turret!(turret_name)
      current_user.update!(credits: current_user.credits - turret_price)
      render json: {
        message: "#{turret_name} achetée et installée !",
        turrets_html: render_to_string(
          partial: 'ships/turret_section',
          formats: [:html],
          locals: { ship: @ship, user_credits: current_user.credits }
        ),
        user_credits: current_user.credits
      }
    else
      render json: { error: "Erreur lors de l'achat de la tourelle." }, status: :unprocessable_entity
    end
  end

  def install_turret
    turret_id = params[:turret_id]
    
    unless @ship.install_turret!(turret_id)
      render json: { error: "Impossible d'installer cette tourelle." }, status: :unprocessable_entity
      return
    end

    render json: {
      message: "Tourelle installée !",
      turrets_html: render_to_string(
        partial: 'ships/turret_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      )
    }
  end

  def uninstall_turret
    turret_id = params[:turret_id]
    
    unless @ship.uninstall_turret!(turret_id)
      render json: { error: "Impossible de désinstaller cette tourelle." }, status: :unprocessable_entity
      return
    end

    render json: {
      message: "Tourelle désinstallée !",
      turrets_html: render_to_string(
        partial: 'ships/turret_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      )
    }
  end

  def sell_turret
    turret_id = params[:turret_id]
    
    sell_price = @ship.sell_turret!(turret_id)
    
    unless sell_price
      render json: { error: "Impossible de vendre cette tourelle." }, status: :unprocessable_entity
      return
    end

    current_user.update!(credits: current_user.credits + sell_price)
    render json: {
      message: "Tourelle vendue pour #{sell_price} crédits !",
      turrets_html: render_to_string(
        partial: 'ships/turret_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      ),
      user_credits: current_user.credits
    }
  end

  def upgrade_weapon_damage
    weapon_id = params[:weapon_id]
    weapon = @ship.ship_weapons.find(weapon_id)
    
    unless weapon.can_afford_damage_upgrade?(current_user.credits)
      redirect_to improve_ship_path(@ship), alert: "Crédits insuffisants pour cette amélioration."
      return
    end

    upgrade_cost = weapon.damage_upgrade_cost
    upgrade_description = weapon.damage_upgrade_description
    
    if weapon.upgrade_damage!
      current_user.update!(credits: current_user.credits - upgrade_cost)
      redirect_to improve_ship_path(@ship), notice: "Dégâts de #{weapon.name} améliorés (#{upgrade_description}) !"
    else
      redirect_to improve_ship_path(@ship), alert: "Erreur lors de l'amélioration."
    end
  end

  def upgrade_weapon_aim
    weapon_id = params[:weapon_id]
    weapon = @ship.ship_weapons.find(weapon_id)
    
    unless weapon.can_afford_aim_upgrade?(current_user.credits)
      redirect_to improve_ship_path(@ship), alert: "Crédits insuffisants pour cette amélioration."
      return
    end

    upgrade_cost = weapon.aim_upgrade_cost
    upgrade_description = weapon.aim_upgrade_description
    
    if weapon.upgrade_aim!
      current_user.update!(credits: current_user.credits - upgrade_cost)
      redirect_to improve_ship_path(@ship), notice: "Précision de #{weapon.name} améliorée (#{upgrade_description}) !"
    else
      redirect_to improve_ship_path(@ship), alert: "Erreur lors de l'amélioration."
    end
  end

  def buy_special_equipment
    equipment_name = params[:equipment_name]
    
    unless Ship::SPECIAL_EQUIPMENT.key?(equipment_name)
      render json: { error: "Équipement invalide." }, status: :unprocessable_entity
      return
    end

    unless @ship.can_buy_special_equipment?(equipment_name, current_user.credits)
      render json: { error: "Crédits insuffisants pour cet équipement." }, status: :unprocessable_entity
      return
    end

    equipment_price = Ship::SPECIAL_EQUIPMENT[equipment_name][:price]
    
    if @ship.buy_special_equipment!(equipment_name)
      current_user.update!(credits: current_user.credits - equipment_price)
      render json: {
        message: "#{equipment_name} acheté avec succès !",
        special_equipment_html: render_to_string(
          partial: 'ships/special_equipment_section',
          formats: [:html],
          locals: { ship: @ship, user_credits: current_user.credits }
        ),
        user_credits: current_user.credits
      }
    else
      render json: { error: "Erreur lors de l'achat de l'équipement." }, status: :unprocessable_entity
    end
  end

  def install_special_equipment
    equipment_id = params[:equipment_id]
    
    unless @ship.install_special_equipment!(equipment_id)
      render json: { error: "Impossible d'installer cet équipement." }, status: :unprocessable_entity
      return
    end

    render json: {
      message: "Équipement installé !",
      special_equipment_html: render_to_string(
        partial: 'ships/special_equipment_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      )
    }
  end

  def uninstall_special_equipment
    equipment_id = params[:equipment_id]
    
    unless @ship.uninstall_special_equipment!(equipment_id)
      render json: { error: "Impossible de désinstaller cet équipement." }, status: :unprocessable_entity
      return
    end

    render json: {
      message: "Équipement désinstallé !",
      special_equipment_html: render_to_string(
        partial: 'ships/special_equipment_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      )
    }
  end

  def sell_special_equipment
    equipment_id = params[:equipment_id]
    
    sell_price = @ship.sell_special_equipment!(equipment_id)
    
    unless sell_price
      render json: { error: "Impossible de vendre cet équipement." }, status: :unprocessable_entity
      return
    end

    current_user.update!(credits: current_user.credits + sell_price)
    render json: {
      message: "Équipement vendu pour #{sell_price} crédits !",
      special_equipment_html: render_to_string(
        partial: 'ships/special_equipment_section',
        formats: [:html],
        locals: { ship: @ship, user_credits: current_user.credits }
      ),
      user_credits: current_user.credits
    }
  end

  def crew
    @available_positions = @ship.available_positions
    @crew_candidates = @ship.available_crew_candidates
  end

  def assign_crew
    position = params[:position]
    assignable_type = params[:assignable_type]
    assignable_id = params[:assignable_id]
    
    if assignable_id.blank?
      # Retirer le membre d'équipage du poste
      crew_member = @ship.crew_member_for_position(position)
      if crew_member
        crew_member.destroy
        render json: { message: "Poste libéré", position: position }
      else
        render json: { error: "Aucun membre d'équipage à retirer" }, status: :unprocessable_entity
      end
      return
    end

    # Assigner un nouveau membre d'équipage
    assignable = assignable_type.constantize.find(assignable_id) rescue nil
    
    unless assignable
      render json: { error: "Membre d'équipage introuvable" }, status: :unprocessable_entity
      return
    end

    # Vérifier si ce membre est déjà assigné à un poste sur ce vaisseau
    existing_assignment = @ship.crew_members.find_by(assignable: assignable)
    if existing_assignment
      render json: { error: "Ce membre est déjà assigné au poste #{existing_assignment.position}" }, status: :unprocessable_entity
      return
    end

    # Retirer l'ancien membre du poste s'il existe
    old_crew_member = @ship.crew_member_for_position(position)
    old_crew_member&.destroy

    # Créer le nouveau membre d'équipage
    crew_member = @ship.crew_members.build(
      position: position,
      assignable: assignable
    )

    if crew_member.save
      render json: { 
        message: "#{assignable.name || assignable.username} assigné(e) au poste #{position}",
        position: position,
        assignable_name: crew_member.assignable_name,
        assignable_type: crew_member.assignable_type_display
      }
    else
      render json: { error: crew_member.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def remove_crew_member
    crew_member_id = params[:crew_member_id]
    crew_member = @ship.crew_members.find_by(id: crew_member_id)
    
    unless crew_member
      render json: { error: "Membre d'équipage introuvable" }, status: :unprocessable_entity
      return
    end

    position = crew_member.position
    crew_member.destroy
    
    render json: { 
      message: "Membre d'équipage retiré du poste #{position}",
      position: position
    }
  end

  def repair
    # Vérification de la compétence Technique
    technique_carac = current_user.user_caracs.joins(:carac).find_by(caracs: { name: "Technique" })
    @technique_mastery = technique_carac&.mastery || 0
    @can_repair = @technique_mastery >= 2
    
    if @can_repair
      # Compétence Réparation du joueur
      reparation_skill = current_user.user_skills.joins(:skill).find_by(skills: { name: "Réparation" })
      @reparation_mastery = reparation_skill&.mastery || 0
      @reparation_bonus = reparation_skill&.bonus || 0
      
      # Inventaire du joueur
      @repair_kits = current_user.user_inventory_objects.joins(:inventory_object)
                                 .find_by(inventory_objects: { name: "Kit de réparation" })
      @components = current_user.user_inventory_objects.joins(:inventory_object)
                                .find_by(inventory_objects: { name: "Composant" })
      
      @repair_kit_count = @repair_kits&.quantity || 0
      @component_count = @components&.quantity || 0
      
      # Coût des kits selon la scale du vaisseau
      @repair_kit_cost = @ship.repair_kit_cost
      
      # Informations sur les droïdes astromecs
      @can_use_astromech = @ship.can_use_astromech_droids?
      @astromech_count = @ship.astromech_droids
      
      # Liste des avaries pour le rôle play
      @ship_damages = helpers.ship_damage_list(@ship)
    end
  end



  def use_repair_kit
    # Vérifications préliminaires
    technique_carac = current_user.user_caracs.joins(:carac).find_by(caracs: { name: "Technique" })
    technique_mastery = technique_carac&.mastery || 0
    
    unless technique_mastery >= 2
      render json: { error: "Compétence Technique insuffisante (minimum 2D)" }, status: :unprocessable_entity
      return
    end

    repair_kit = current_user.user_inventory_objects.joins(:inventory_object)
                             .find_by(inventory_objects: { name: "Kit de réparation" })
    components = current_user.user_inventory_objects.joins(:inventory_object)
                             .find_by(inventory_objects: { name: "Composant" })
    
    kit_cost = @ship.repair_kit_cost
    components_needed = rand(1..3)
    
    unless repair_kit && repair_kit.quantity >= kit_cost
      render json: { error: "Kits de réparation insuffisants (#{kit_cost} requis)" }, status: :unprocessable_entity
      return
    end

    unless components && components.quantity >= components_needed
      render json: { error: "Composants insuffisants (#{components_needed} requis)" }, status: :unprocessable_entity
      return
    end

    if @ship.hp_current >= @ship.hp_max
      render json: { error: "Le vaisseau est déjà entièrement réparé" }, status: :unprocessable_entity
      return
    end

    # Jet de dés de Réparation
    reparation_skill = current_user.user_skills.joins(:skill).find_by(skills: { name: "Réparation" })
    mastery = reparation_skill&.mastery || 0
    bonus = reparation_skill&.bonus || 0
    
    dice_results = Array.new(mastery) { rand(1..6) }
    total_roll = dice_results.sum + bonus
    hp_restored = (total_roll / 2.0).floor
    
    # Application des soins
    ActiveRecord::Base.transaction do
      new_hp = [@ship.hp_current + hp_restored, @ship.hp_max].min
      actual_hp_restored = new_hp - @ship.hp_current
      
      @ship.update!(hp_current: new_hp)
      repair_kit.decrement!(:quantity, kit_cost)
      components.decrement!(:quantity, components_needed)
    end

    render json: {
      message: "#{kit_cost} kit(s) de réparation et #{components_needed} composant(s) utilisés ! #{actual_hp_restored} points de blindage restaurés (jet: #{total_roll})",
      hp_current: @ship.hp_current,
      hp_max: @ship.hp_max,
      repair_kit_count: repair_kit.quantity,
      component_count: components.quantity,
      dice_details: "#{mastery}D + #{bonus} = #{dice_results.join('+')} + #{bonus} = #{total_roll}"
    }
  end

  def deploy_astromech_droid
    # Vérifications préliminaires
    unless @ship.can_use_astromech_droids?
      render json: { error: "Ce vaisseau ne peut pas utiliser de droïdes astromecs (scale 3+ requis)" }, status: :unprocessable_entity
      return
    end

    unless @ship.has_astromech_droids?
      render json: { error: "Aucun droïde astromec disponible" }, status: :unprocessable_entity
      return
    end

    if @ship.hp_current >= @ship.hp_max
      render json: { error: "Le vaisseau est déjà entièrement réparé" }, status: :unprocessable_entity
      return
    end

    # Génération aléatoire des résultats
    hp_to_restore = rand(10..30)
    components_needed = rand(1..3)
    droid_destroyed = rand(1..100) <= 10 # 10% de chance

    # Vérifier les composants disponibles
    components = current_user.user_inventory_objects.joins(:inventory_object)
                             .find_by(inventory_objects: { name: "Composant" })
    
    has_enough_components = components && components.quantity >= components_needed
    
    # Ajuster les HP restaurés selon les composants
    unless has_enough_components
      hp_to_restore = 5
      components_needed = 0
    end

    # Application des effets
    ActiveRecord::Base.transaction do
      # Restaurer les HP
      new_hp = [@ship.hp_current + hp_to_restore, @ship.hp_max].min
      actual_hp_restored = new_hp - @ship.hp_current
      @ship.update!(hp_current: new_hp)
      
      # Consommer les composants si disponibles
      if has_enough_components && components_needed > 0
        components.decrement!(:quantity, components_needed)
      end
      
      # Détruire le droïde si malchanceux
      if droid_destroyed
        @ship.decrement!(:astromech_droids, 1)
      end
    end

    # Préparer le message de résultat
    message = "Mission accomplie ! Le droïde astromec a restauré #{actual_hp_restored} points de blindage."
    
    if has_enough_components
      message += " #{components_needed} composant(s) utilisé(s)."
    else
      message += " Réparation limitée par manque de composants."
    end
    
    if droid_destroyed
      message += " ⚠️ Le droïde a été détruit par un tir ennemi !"
    else
      message += " Le droïde est rentré sain et sauf."
    end

    render json: {
      message: message,
      hp_current: @ship.hp_current,
      hp_max: @ship.hp_max,
      hp_restored: actual_hp_restored,
      components_used: has_enough_components ? components_needed : 0,
      droid_destroyed: droid_destroyed,
      astromech_droids: @ship.astromech_droids,
      component_count: components&.quantity || 0
    }
  end

  private

  def set_ship
    @ship = Ship.find(params[:id])
  end

  def ship_params
    params.require(:ship).permit(
      :name, :price, :brand, :model, :description, :size, :max_passengers, 
      :min_crew, :hp_max, :hp_current, :hyperdrive_rating, :backup_hyperdrive, 
      :image, :parent_ship_id, :astromech_droids
    )
  end

  def update_ship_skills(ship)
    # Compétences liées au vaisseau
    ships_skills_params = params[:ships_skills] || []
    ships_skills_params.each do |skill_hash|
      next if skill_hash["skill_id"].blank?
      skill = Skill.find_by(id: skill_hash["skill_id"])
      next unless skill
      ships_skill = ship.ships_skills.find_or_initialize_by(skill: skill)
      ships_skill.update(
        mastery: skill_hash["mastery"].to_i,
        bonus: skill_hash["bonus"].to_i
      )
    end
  end

  def update_ship_weapons(ship)
    # Arme principale
    if params[:main_weapon].present?
      ship.ship_weapons.create(
        name: params[:main_weapon],
        weapon_type: 'main',
        damage_mastery: 5,
        damage_bonus: 0,
        aim_mastery: 0,
        aim_bonus: 0,
        price: 0
      )
    end
    # Arme secondaire
    if params[:secondary_weapon].present?
      ship.ship_weapons.create(
        name: params[:secondary_weapon],
        weapon_type: 'secondary',
        damage_mastery: 4,
        damage_bonus: 0,
        aim_mastery: 0,
        aim_bonus: 0,
        price: 0
      )
    end
    
    # Tourelles
    if params[:turrets] == '1' && params[:turret_count].to_i > 0 && params[:turret_type].present?
      turret_config = Ship::PREDEFINED_WEAPONS[params[:turret_type]]
      if turret_config && turret_config[:weapon_type] == 'tourelle'
        (1..params[:turret_count].to_i).each do |i|
          ship.ship_weapons.create(
            name: params[:turret_type],
            weapon_type: 'tourelle',
            damage_mastery: turret_config[:damage_mastery],
            damage_bonus: turret_config[:damage_bonus],
            aim_mastery: turret_config[:aim_mastery],
            aim_bonus: turret_config[:aim_bonus],
            special: turret_config[:special],
            price: 0  # Prix 0 pour les tourelles créées avec le vaisseau
          )
        end
      end
    end

    # Torpilles
    if params[:torpilles] == '1' && params[:torpilles_count].to_i > 0
      ship.ship_weapons.create(
        name: 'Lance-Torpilles à protons',
        weapon_type: 'torpille',
        quantity_max: params[:torpilles_count].to_i,
        quantity_current: params[:torpilles_count].to_i,
        damage_mastery: 8,
        damage_bonus: 0,
        aim_mastery: 0,
        aim_bonus: 0,
        price: 0
      )
      ship.update(torpilles: true)
    else
      ship.update(torpilles: false)
    end
    # Missiles
    if params[:missiles] == '1' && params[:missiles_count].to_i > 0
      ship.ship_weapons.create(
        name: 'Lance-Missiles à concussion',
        weapon_type: 'missile',
        quantity_max: params[:missiles_count].to_i,
        quantity_current: params[:missiles_count].to_i,
        damage_mastery: 6,
        damage_bonus: 0,
        aim_mastery: 0,
        aim_bonus: 0,
        price: 0
      )
      ship.update(missiles: true)
    else
      ship.update(missiles: false)
    end
  end
end
