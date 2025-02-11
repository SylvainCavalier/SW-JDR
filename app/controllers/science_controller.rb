class ScienceController < ApplicationController
  before_action :verify_bio_savant

  def index
  end

  def science
    # Vous pouvez initialiser des variables nécessaires ici
  end

  def list
    @ingredients = InventoryObject.where(category: 'ingredient').where(rarity: ['Commun', 'Unco'])
  end

  def buy_inventory_object
    inventory_object = InventoryObject.find(params[:inventory_object_id])
    user_inventory_object = current_user.user_inventory_objects.find_or_initialize_by(inventory_object: inventory_object)

    if current_user.credits >= inventory_object.price
      current_user.credits -= inventory_object.price
      user_inventory_object.quantity ||= 0
      user_inventory_object.quantity += 1

      ActiveRecord::Base.transaction do
        current_user.save!
        user_inventory_object.save!
      end

      render json: { new_quantity: user_inventory_object.quantity }, status: :ok
    else
      render json: { error: "Crédits insuffisants" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Utilisateur ou objet introuvable" }, status: :not_found
  end

  def settings
    skill = Skill.find_by(name: "Ingénierie")
    @engineering_skill = current_user.user_skills.find_by(skill: skill)
  end

  def update_settings
    skill = Skill.find_by(name: "Ingénierie")
    user_skill = current_user.user_skills.find_or_initialize_by(skill: skill)
  
    if user_skill.update(skill_params)
      redirect_to settings_science_index_path, notice: "Les réglages ont été mis à jour."
    else
      redirect_to settings_science_index_path, alert: "Erreur lors de la mise à jour des réglages."
    end
  end

  def crafts
    @craftables = InventoryObject.where(name: CRAFT_RECIPES.keys).order(:name)
  end
  
  def attempt_craft
    craft_params = params[:craft]
    item_to_craft = InventoryObject.find(craft_params[:item_id])
    recipe = CRAFT_RECIPES[item_to_craft.name]
  
    difficulty = recipe[:difficulty]
    ingredients = recipe[:ingredients]
  
    if ingredients.nil?
      render json: { success: false, error: "Recette inconnue pour #{item_to_craft.name}.", refresh: true }, status: :unprocessable_entity
      return
    end
  
    # Vérification des ingrédients
    missing_ingredients = []
    ingredients.each do |ingredient_name, quantity|
      user_ingredient = current_user.user_inventory_objects.joins(:inventory_object)
                                  .find_by("LOWER(inventory_objects.name) = ?", ingredient_name.downcase)
      if user_ingredient.nil? || user_ingredient.quantity < quantity
        missing_ingredients << ingredient_name
      end
    end
  
    if missing_ingredients.any?
      Rails.logger.debug "Craft impossible : #{missing_ingredients.join(', ')} manquants."
      render json: { 
        success: false, 
        error: "Craft impossible : il vous manque #{missing_ingredients.join(', ')}.",
        refresh: true 
      }, status: :unprocessable_entity
      return
    end
  
    # Jet de dés
    skill = current_user.user_skills.find_by(skill: Skill.find_by(name: "Ingénierie"))
    roll = roll_dice(skill.mastery) + skill.bonus
  
    if roll >= difficulty
      # Craft réussi
      user_item = current_user.user_inventory_objects.find_or_initialize_by(inventory_object: item_to_craft)

      if user_item.new_record?
        user_item.quantity = 1  # Assigner une quantité initiale si l'objet n'existait pas encore
        user_item.save!
      else
        user_item.increment!(:quantity)
      end
  
      consume_ingredients(ingredients)
  
      Rails.logger.debug "Craft réussi : #{item_to_craft.name}, ID : #{item_to_craft.id}"
      render json: { 
        success: true, 
        item: { 
          id: item_to_craft.id, 
          name: item_to_craft.name, 
          new_quantity: user_item.quantity 
        },
        ingredients: ingredients.map do |ingredient_name, quantity|
          user_ingredient = current_user.user_inventory_objects.joins(:inventory_object)
                                        .find_by("LOWER(inventory_objects.name) = ?", ingredient_name.downcase)
          { name: ingredient_name, new_quantity: user_ingredient&.quantity || 0 }
        end
      }
    else
      # Craft raté
      Rails.logger.debug "Craft raté, retour JSON : Craft raté. Vous avez perdu les ingrédients."
      consume_ingredients(ingredients) if rand < 0.5
      render json: { 
        success: false, 
        error: "Craft raté. Vous avez perdu les ingrédients.",
      }, status: :unprocessable_entity
    end
  end

  def attempt_transfer
    transfer_data = transfer_params
    item_id = transfer_data[:item_id]
    player_id = transfer_data[:player_id]
    
    Rails.logger.debug "Tentative de transfert : paramètres reçus - item_id: #{item_id}, player_id: #{player_id}, transfer_data: #{transfer_data.inspect}"
  
    if item_id.blank? || player_id.blank?
      render json: { success: false, error: "Paramètres manquants ou invalides : #{transfer_data}" }, status: :unprocessable_entity
      return
    end
  
    user_item = current_user.user_inventory_objects.find_by(inventory_object_id: item_id)
    
    unless user_item
      render json: { success: false, error: "Vous ne possédez pas cet objet dans votre inventaire." }, status: :unprocessable_entity
      return
    end
  
    if user_item.quantity.to_i > 0
      # Décrémente l'inventaire du joueur actuel
      user_item.decrement!(:quantity)
  
      # Ajoute l'objet à l'inventaire du joueur cible
      target_player = User.find(player_id)
      target_inventory = target_player.user_inventory_objects.find_or_initialize_by(inventory_object_id: item_id)
      target_inventory.quantity ||= 0
      target_inventory.increment!(:quantity)
  
      # Vérifie si le patch doit être équipé
      if InventoryObject.find(item_id).category == "patch" && target_player.patch.nil?
        target_player.update!(patch: item_id)
        render json: { 
          success: true, 
          message: "Objet transféré et équipé à #{target_player.username}.",
          item: { 
            id: item_id, 
            new_quantity: user_item.quantity 
          }
        }
      else
        render json: { 
          success: true, 
          message: "Objet transféré avec succès à #{target_player.username}.",
          item: { 
            id: item_id, 
            new_quantity: user_item.quantity 
          }
        }
      end
    else
      render json: { success: false, error: "Quantité insuffisante pour transférer cet objet." }, status: :unprocessable_entity
    end
  end

  def players
    players = Group.find_by(name: "PJ")&.users || []
    render json: players.map { |player| { id: player.id, username: player.username } }
  end

  def bestiaire
    @animals = Pet.where(creature: true).where.not(status: Status.find_by(name: "Mort")).order(:name)
  end

  def showbestiaire
    @pet = Pet.find(params[:id])
  end
  
  private

  def transfer_params
    params.require(:science).permit(:item_id, :player_id)
  end
  
  def consume_ingredients(ingredients)
    ingredients.each do |ingredient_name, quantity|
      user_ingredient = current_user.user_inventory_objects.joins(:inventory_object)
                  .find_by("LOWER(inventory_objects.name) = ?", ingredient_name.downcase)
      if user_ingredient
        Rails.logger.debug "Consommation de #{quantity} #{ingredient_name} (avant : #{user_ingredient.quantity})"
        user_ingredient.decrement!(:quantity, quantity)
        Rails.logger.debug "Après consommation : #{user_ingredient.quantity}"
      else
        Rails.logger.error "Ingrédient introuvable : #{ingredient_name}"
      end
    end
  end

  def roll_dice(number_of_dice, sides = 6)
    results = Array.new(number_of_dice) { rand(1..sides) }
    Rails.logger.debug "Jet : #{results.inspect}"
    results.sum
  end

  def skill_params
    params.require(:engineering).permit(:mastery, :bonus)
  end

  def verify_bio_savant
    unless current_user.classe_perso.name == "Bio-savant"
      redirect_to root_path, alert: "Accès réservé aux Bio-savants."
    end
  end
end