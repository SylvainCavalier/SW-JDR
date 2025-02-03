class CombatController < ApplicationController

  def new
    @enemy = Enemy.new
    @enemy.enemy_skills.build(skill: Skill.find_by(name: "Résistance Corporelle"))
  end

  # Page de gestion du combat (MJ)
  def index
    @combat_active = Rails.cache.fetch("combat_active") || false
    @enemies = Enemy.order(:enemy_type, :number)
    new # <-- Appelle la méthode `new` pour préremplir les skills !
    render "mj/combat"
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
      flash[:notice] = "Ennemi ajouté avec succès."
    else
      puts "❌ Erreurs lors de l'ajout de l'ennemi : #{@enemy.errors.full_messages}"
      flash[:alert] = "Erreur lors de l'ajout de l'ennemi : #{@enemy.errors.full_messages.join(', ')}"
    end
  
    redirect_to mj_combat_path
  end

  # Supprimer un ennemi
  def remove_enemy
    enemy = Enemy.find(params[:id])
    if enemy.destroy
      flash[:notice] = "Ennemi supprimé."
    else
      flash[:alert] = "Erreur lors de la suppression de l'ennemi."
    end
    redirect_to mj_combat_path
  end

  def update_stat
    Rails.logger.debug "📌 Paramètres reçus : #{params.inspect}"
    @enemy = Enemy.find(params[:id])
    field = params.keys.find { |key| ["hp_current", "shield_current"].include?(key) }
  
    if field && @enemy.update(field => params[field].to_i)
      render json: { success: true, hp_current: @enemy.hp_current, shield_current: @enemy.shield_current }
    else
      render json: { success: false, errors: @enemy.errors.full_messages }, status: :unprocessable_entity
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
    
    redirect_to mj_combat_path
  end

  def increment_turn
    combat_state = CombatState.first_or_create(turn: 1)
    combat_state.update(turn: combat_state.turn + 1)
    
    render json: { success: true, turn: combat_state.turn }
  end
  
  def decrement_turn
    combat_state = CombatState.first_or_create(turn: 1)
    new_turn = [1, combat_state.turn - 1].max
    combat_state.update(turn: new_turn)
    
    render json: { success: true, turn: new_turn }
  end

  private

  def enemy_params
    params.require(:enemy).permit(
      :enemy_type, :hp_max, :shield_max, :vitesse,
      enemy_skills_attributes: [:id, :mastery, :bonus, :skill_id, :_destroy]
    )
  end
end