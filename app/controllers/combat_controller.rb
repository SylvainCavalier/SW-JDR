class CombatController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!
  before_action :set_current_user

  def index
    @enemy = Enemy.new
    @enemy.enemy_skills.build(skill: Skill.find_by(name: "Résistance Corporelle"))
    @enemies = Enemy.order(:enemy_type, :number)
    @combat_actions = CombatAction.order(created_at: :desc).limit(50)

    # Données pour la modale de soins réutilisable
    pj_group = Group.find_by(name: "PJ")
    @heal_users = User.joins(:group).where(groups: { name: "PJ" }).order(:username).to_a
    @heal_users.delete(current_user)
    @heal_users.unshift(current_user)

    @heal_pets = @heal_users.map(&:pet).compact
    @heal_items = current_user.user_inventory_objects.includes(:inventory_object)
    render "pages/combat"
  end

  # Ajouter un ennemi
  def add_enemy
    @enemy = Enemy.new(enemy_params)
    
    # ✅ On définit le type avant de compter
    enemy_type = params[:enemy][:enemy_type]
    @enemy.enemy_type = enemy_type
    
    # ✅ On assigne le bon numéro en comptant les ennemis existants
    @enemy.number = Enemy.where(enemy_type: enemy_type).count + 1
    
    @enemy.hp_current = @enemy.hp_max
    @enemy.shield_current = @enemy.shield_max
    @enemy.status ||= "En forme"
    puts "📌 Type: #{@enemy.enemy_type}, Number: #{@enemy.number}, HP: #{@enemy.hp_max}, Status: #{@enemy.status}"
  
    if @enemy.save
      broadcast_participant_update(@enemy)
      flash[:notice] = "Ennemi ajouté avec succès."
    else
      puts "❌ Erreurs lors de l'ajout de l'ennemi : #{@enemy.errors.full_messages}"
      flash[:alert] = "Erreur lors de l'ajout de l'ennemi : #{@enemy.errors.full_messages.join(', ')}"
    end
  
    redirect_to combat_path
  end

  # Supprimer un ennemi
  def remove_enemy
    enemy = Enemy.find(params[:id])
    if enemy.destroy
      Turbo::StreamsChannel.broadcast_remove_to(
        "combat_updates",
        target: enemy
      )
      flash[:notice] = "Ennemi supprimé."
    else
      flash[:alert] = "Erreur lors de la suppression de l'ennemi."
    end
    redirect_to combat_path
  end

  def update_stat
    Rails.logger.debug "📌 Paramètres reçus : #{params.inspect}"
    
    # Vérification des paramètres requis
    unless params[:id].present? && params[:type].present?
      render json: { success: false, error: "Paramètres manquants" }, status: :bad_request
      return
    end

    begin
      @participant = params[:type].constantize.find(params[:id])
    rescue NameError, ActiveRecord::RecordNotFound
      render json: { success: false, error: "Participant non trouvé" }, status: :not_found
      return
    end
    
    # Vérification des permissions
    unless can_modify_participant?(@participant)
      render json: { success: false, error: "Vous n'avez pas les permissions nécessaires" }, status: :unauthorized
      return
    end

    field = params.keys.find { |key| ["hp_current", "shield_current", "echani_shield_current"].include?(key) }
    unless field
      render json: { success: false, error: "Champ invalide" }, status: :bad_request
      return
    end

    old_value = @participant.send(field)
    new_value = params[field].to_i
    
    if @participant.update(field => new_value)
      # Création de l'action de combat
      action_type = case field
                   when "hp_current"
                     new_value > old_value ? "heal" : "damage"
                   when "shield_current", "echani_shield_current"
                     "shield"
                   end
                   
      CombatAction.create!(
        actor: current_user,
        target: @participant,
        action_type: action_type,
        value: (new_value - old_value).abs
      )
      
      # Broadcast unifié pour les mises à jour
      broadcast_value_update(@participant, field)
      
      render json: { success: true }
    else
      render json: { success: false, errors: @participant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_pj_to_combat
    if params[:vitesse].present?
      current_user.update(vitesse: params[:vitesse].to_i)
      flash[:notice] = "Votre initiative a été enregistrée."
    else
      flash[:alert] = "Veuillez indiquer une vitesse valide."
    end
    redirect_to combat_path
  end

  def add_pet_to_combat
    if current_user.pet_id.present?
      pet = Pet.find_by(id: current_user.pet_id)
      
      if pet
        pet.update(vitesse: params[:vitesse])
        flash[:notice] = "#{pet.name} a rejoint le combat avec une vitesse de #{params[:vitesse]}."
      else
        flash[:alert] = "Impossible d'ajouter le pet, une erreur est survenue."
      end
    else
      flash[:alert] = "Vous n'avez pas de pet associé."
    end
  
    redirect_to combat_path
  end

  def remove_participant
    participant = params[:type].constantize.find(params[:id])
    
    if participant.update(vitesse: nil)
      flash[:notice] = "#{participant.is_a?(User) ? 'Le joueur' : 'Le pet'} a été retiré du combat."
    else
      flash[:alert] = "Impossible de retirer #{participant.is_a?(User) ? 'le joueur' : 'le pet'} du combat."
    end
    
    redirect_to combat_path
  end

  def increment_turn
    combat_state = CombatState.first_or_create(turn: 1)
    combat_state.update(turn: combat_state.turn + 1)
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "combat_updates",
      target: "turn_counter",
      partial: "pages/turn_counter",
      locals: { combat_state: combat_state, current_user: current_user }
    )
    
    render json: { success: true }
  end
  
  def decrement_turn
    combat_state = CombatState.first_or_create(turn: 1)
    new_turn = [1, combat_state.turn - 1].max
    combat_state.update(turn: new_turn)
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "combat_updates",
      target: "turn_counter",
      partial: "pages/turn_counter",
      locals: { combat_state: combat_state, current_user: current_user }
    )
    
    render json: { success: true }
  end

  def update_player_stat
    Rails.logger.debug "📌 Paramètres reçus pour update_player_stat : #{params.inspect}"
    @participant = params[:type].constantize.find(params[:id])
    
    # Vérification des permissions
    if @participant.is_a?(User) && @participant != current_user && current_user.group.name != "MJ"
      render json: { success: false, error: "Vous ne pouvez pas modifier les statistiques d'un autre joueur" }, status: :unauthorized
      return
    elsif @participant.is_a?(Pet) && @participant.id != current_user.pet_id && current_user.group.name != "MJ"
      render json: { success: false, error: "Vous ne pouvez pas modifier les statistiques d'un pet qui ne vous appartient pas" }, status: :unauthorized
      return
    end

    field = params.keys.find { |key| ["hp_current", "shield_current"].include?(key) }
    
    if field && @participant.update(field => params[field].to_i)
      # Broadcast de la mise à jour des valeurs uniquement
      Turbo::StreamsChannel.broadcast_replace_to(
        "combat_updates",
        target: "#{dom_id(@participant)}_#{field == 'hp_current' ? 'hp' : 'shield'}_value",
        partial: "pages/combat_value",
        locals: { 
          participant: @participant, 
          field: field,
          current: @participant.send(field),
          max: field == 'hp_current' ? @participant.hp_max : @participant.shield_max
        }
      )

      render json: { success: true }
    else
      render json: { success: false, errors: @participant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def heal_enemy
    begin
      enemy = Enemy.find(params[:enemy_id])

      unless enemy.ally?
        render json: { error: "Cet ennemi n'est pas un allié." }, status: :unprocessable_entity
        return
      end

      heal_item = current_user.user_inventory_objects.find_by(inventory_object_id: params[:item_id])
      inventory_object = heal_item&.inventory_object

      if inventory_object.nil?
        render json: { error: "Objet de soin introuvable." }, status: :unprocessable_entity
        return
      end

      if heal_item.nil? || heal_item.quantity <= 0
        render json: { error: "Objet de soin invalide ou quantité insuffisante." }, status: :unprocessable_entity
        return
      end

      if enemy.hp_current >= enemy.hp_max
        render json: { error_message: "#{enemy.name} a déjà tous ses PV !" }, status: :unprocessable_entity
        return
      end

      healed_points, new_status = inventory_object.apply_effects(enemy, current_user)

      if healed_points <= 0 && new_status.nil?
        render json: { error_message: "Cet objet ne peut pas être utilisé dans ce contexte." }, status: :unprocessable_entity
        return
      end

      new_hp = [enemy.hp_current + healed_points, enemy.hp_max].min

      ActiveRecord::Base.transaction do
        if inventory_object.name != "Homéopathie" && healed_points > 0
          heal_item.quantity -= 1
          heal_item.save!
        end

        enemy.update!(hp_current: new_hp)

        if new_status
          enemy.set_status(new_status)
        end
      end

      render json: {
        target_name: enemy.name,
        new_hp: new_hp,
        hp_max: enemy.hp_max,
        item_quantity: heal_item&.quantity || "illimité",
        healed_points: healed_points,
        new_status: new_status
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Ennemi introuvable." }, status: :not_found
    rescue => e
      Rails.logger.error "Erreur heal_enemy: #{e.message}"
      render json: { error: "Une erreur inattendue s'est produite." }, status: :internal_server_error
    end
  end

  def update_status
    participant_type = params[:participant_type]
    participant = participant_type.constantize.find(params[:participant_id])
    status = Status.find(params[:status_id])

    success = false

    if participant.is_a?(Enemy)
      success = participant.update(status: status.name)
    elsif participant.is_a?(User)
      participant.user_statuses.destroy_all
      success = participant.user_statuses.create(status: status)
    elsif participant.is_a?(Pet)
      participant.pet_statuses.destroy_all
      success = participant.pet_statuses.create(status: status)
    end

    if success
      CombatAction.create!(
        actor: current_user,
        target: participant,
        action_type: "status",
        value: status.name
      )
      
      broadcast_participant_update(participant)
      render json: { success: true }
    else
      render json: { success: false, error: "Erreur lors de la mise à jour du statut" }, status: :unprocessable_entity
    end
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def enemy_params
    params.require(:enemy).permit(
      :enemy_type, :hp_max, :shield_max, :vitesse, :ally,
      enemy_skills_attributes: [:id, :mastery, :bonus, :skill_id, :_destroy]
    )
  end

  def broadcast_participant_update(participant)
    # On envoie une seule mise à jour avec les données appropriées
    Turbo::StreamsChannel.broadcast_update_to(
      "combat_updates",
      targets: ["#{dom_id(participant)}_hp", "#{dom_id(participant)}_shield"],
      partial: "pages/combat_stats",
      locals: { participant: participant, current_user: Current.user }
    )
  end

  def broadcast_turn_update(combat_state)
    # On envoie une seule mise à jour du tour
    Turbo::StreamsChannel.broadcast_replace_to(
      "combat_updates",
      target: "turn_counter",
      partial: "pages/turn_counter",
      locals: { combat_state: combat_state, current_user: Current.user }
    )
  end

  def can_modify_participant?(participant)
    return true if current_user.group.name == "MJ"
    
    case participant
    when User
      participant == current_user
    when Pet
      participant.id == current_user.pet_id
    when Enemy
      current_user.group.name == "MJ"
    else
      false
    end
  end

  def broadcast_value_update(participant, field)
    Turbo::StreamsChannel.broadcast_replace_to(
      "combat_updates",
      target: "#{dom_id(participant)}_#{field == 'hp_current' ? 'hp' : 'shield'}_value",
      partial: "pages/combat_value",
      locals: { 
        participant: participant, 
        field: field,
        current: participant.send(field),
        max: field == 'hp_current' ? participant.hp_max : participant.shield_max
      }
    )
  end
end