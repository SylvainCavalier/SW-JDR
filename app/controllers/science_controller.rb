class ScienceController < ApplicationController
  before_action :verify_bio_savant, except: [:players]

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
    dead_status = Status.find_by(name: "Mort")
  
    # Récupère l'identifiant du pet associé au current_user, s'il existe
    user_pet_id = current_user.pet_id

    @animals = Pet.joins(:pet_statuses).where(category: "animal").where.not(pet_statuses: { status_id: dead_status.id }).order(:name)
  end

  def showbestiaire
    @pet = Pet.find(params[:id])
  end

  def genetique
  end

  def labo
    @genes = Gene.where(positive: true)
    @user_genes = current_user.user_genes.includes(:gene).index_by(&:gene_id)
    @study_points = current_user.study_points
    @fioles = current_user.user_inventory_objects.joins(:inventory_object).find_by(inventory_objects: { name: "Fiole" })&.quantity || 0
  end

  def recherche_gene
    if current_user.study_points <= 0
      render json: { error: "Pas assez de points d’étude" }, status: :unprocessable_entity and return
    end

    fiole = current_user.user_inventory_objects.joins(:inventory_object).find_by(inventory_objects: { name: "Fiole" })
    if fiole.nil? || fiole.quantity <= 0
      render json: { error: "Pas de fiole disponible" }, status: :unprocessable_entity and return
    end

    # Consommation
    current_user.update!(study_points: current_user.study_points - 1)
    fiole.decrement!(:quantity)

    # Tentative d’étude (40% de succès)
    if rand < 0.5
      gene = Gene.where(positive: true).sample
      user_gene = current_user.user_genes.find_by(gene: gene)

      if user_gene
        if user_gene.level < 3
          user_gene.increment!(:level)
          render json: { success: true, upgrade: true, property: gene.property, level: user_gene.level }
        else
          render json: { success: false }
        end
      else
        UserGene.create!(user: current_user, gene: gene, level: 1)
        render json: { success: true, upgrade: false, property: gene.property, level: 1 }
      end
    else
      render json: { success: false }
    end
  end

  def cultiver
    @embryos = current_user.embryos.where(status: 'stocké').order(created_at: :desc)
    @creature_types = Embryo::CREATURE_TYPES
    @eprouvettes = current_user.user_inventory_objects.joins(:inventory_object)
                              .find_by(inventory_objects: { name: "Jeu d'éprouvettes" })&.quantity || 0
    @matiere_organique = current_user.user_inventory_objects.joins(:inventory_object)
                                    .find_by(inventory_objects: { name: "Matière organique" })&.quantity || 0
  end

  def create_embryo
    # Vérifier les ingrédients
    eprouvettes = current_user.user_inventory_objects.joins(:inventory_object)
                             .find_by(inventory_objects: { name: "Jeu d'éprouvettes" })
    matiere = current_user.user_inventory_objects.joins(:inventory_object)
                         .find_by(inventory_objects: { name: "Matière organique" })

    if eprouvettes.nil? || eprouvettes.quantity < 1
      render json: { success: false, error: "Vous n'avez pas de jeu d'éprouvettes." }, status: :unprocessable_entity
      return
    end

    if matiere.nil? || matiere.quantity < 1
      render json: { success: false, error: "Vous n'avez pas de matière organique." }, status: :unprocessable_entity
      return
    end

    # Consommer les ingrédients
    eprouvettes.decrement!(:quantity)
    matiere.decrement!(:quantity)

    # Jet de chance (1d12)
    luck_bonus = current_user.luck ? 1 : 0
    dice_roll = rand(1..12) + luck_bonus
    success_threshold = 5

    if dice_roll >= success_threshold
      # Succès - Créer l'embryon
      creature_type = embryo_params[:creature_type]
      creature_stats = Embryo::CREATURE_TYPES[creature_type] || {}

      embryo = current_user.embryos.create!(
        name: embryo_params[:name],
        creature_type: creature_type,
        race: embryo_params[:race],
        gender: embryo_params[:gender],
        status: 'stocké',
        weapon: creature_stats['weapon'],
        damage_1: creature_stats['damage'] || 0,
        damage_bonus_1: creature_stats['damage_bonus'] || 0,
        special_traits: creature_stats['special_traits'] || [],
        force: false,
        size: creature_stats['size'],
        weight: creature_stats['weight'],
        hp_max: creature_stats['hp_max'] || 0
      )

      render json: {
        success: true,
        dice_roll: dice_roll,
        message: "Embryon créé avec succès !",
        embryo: {
          id: embryo.id,
          name: embryo.name,
          creature_type: embryo.creature_type,
          race: embryo.race,
          gender: embryo.gender
        },
        new_eprouvettes: eprouvettes.quantity,
        new_matiere: matiere.quantity
      }
    else
      # Échec
      render json: {
        success: false,
        dice_roll: dice_roll,
        error: "La culture a échoué... Les ingrédients ont été consommés."
      }
    end
  end

  def gestation
    @tubes = (1..3).map do |tube_num|
      embryo = current_user.embryos.in_gestation.find_by(gestation_tube: tube_num)
      { number: tube_num, embryo: embryo }
    end
    @embryos_ready = current_user.embryos.where(status: 'éclos')
  end

  def traits
    @embryos = current_user.embryos.available_for_modification.order(created_at: :desc)
    @modified_embryos = current_user.embryos.modified_not_gestating.order(created_at: :desc)
    @user_genes = current_user.user_genes.includes(:gene).where('level > 0')
    @eprouvettes = get_inventory_quantity("Jeu d'éprouvettes")
    @matiere_organique = get_inventory_quantity("Matière organique")
  end

  # Calcul des probabilités AJAX
  def calculate_probabilities
    genes_data = params[:genes] || []
    genes_with_levels = genes_data.map do |g|
      { gene_id: g[:gene_id].to_i, level: g[:level].to_i }
    end

    probabilities = Embryo.calculate_probabilities(genes_with_levels)
    costs = Embryo::TRAIT_COSTS[genes_with_levels.size] || { eprouvettes: 0, matiere: 0 }

    render json: {
      probabilities: probabilities,
      costs: costs
    }
  end

  # Application des traits génétiques
  def apply_traits
    embryo = current_user.embryos.find(params[:embryo_id])
    genes_data = params[:genes] || []

    if genes_data.empty? || genes_data.size > 3
      render json: { success: false, error: "Sélectionnez entre 1 et 3 gènes." }, status: :unprocessable_entity
      return
    end

    genes_with_levels = genes_data.map do |g|
      { gene_id: g[:gene_id].to_i, level: g[:level].to_i }
    end

    # Vérifier les coûts
    costs = Embryo::TRAIT_COSTS[genes_with_levels.size]
    eprouvettes = get_user_inventory("Jeu d'éprouvettes")
    matiere = get_user_inventory("Matière organique")

    if eprouvettes.nil? || eprouvettes.quantity < costs[:eprouvettes]
      render json: { success: false, error: "Éprouvettes insuffisantes (#{costs[:eprouvettes]} requises)." }, status: :unprocessable_entity
      return
    end

    if matiere.nil? || matiere.quantity < costs[:matiere]
      render json: { success: false, error: "Matière organique insuffisante (#{costs[:matiere]} requise)." }, status: :unprocessable_entity
      return
    end

    # Consommer les ressources
    eprouvettes.decrement!(:quantity, costs[:eprouvettes])
    matiere.decrement!(:quantity, costs[:matiere])

    # Appliquer les traits
    user_genes_to_consume = genes_with_levels.map do |g|
      { gene_id: g[:gene_id], level: g[:level] }
    end

    result = embryo.apply_genetic_traits!(genes_with_levels, user_genes_to_consume)

    render json: result.merge(
      new_eprouvettes: eprouvettes.quantity,
      new_matiere: matiere.quantity
    )
  end

  # Mettre en gestation
  def start_gestation
    embryo = current_user.embryos.find(params[:embryo_id])
    result = embryo.start_gestation!

    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  # Recycler un embryon
  def recycle_embryo
    embryo = current_user.embryos.find(params[:embryo_id])
    result = embryo.recycle!

    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  # Voir les détails d'un embryon en gestation
  def show_embryo
    @embryo = current_user.embryos.find(params[:id])
    render json: {
      id: @embryo.id,
      name: @embryo.name,
      creature_type: @embryo.creature_type,
      race: @embryo.race,
      gender: @embryo.gender,
      hp_max: @embryo.hp_max,
      damage_1: @embryo.damage_1,
      damage_bonus_1: @embryo.damage_bonus_1,
      weapon: @embryo.weapon,
      special_traits: @embryo.special_traits,
      status: @embryo.status,
      gestation_days_remaining: @embryo.gestation_days_remaining,
      gestation_days_total: @embryo.gestation_days_total,
      skills: @embryo.embryo_skills.includes(:skill).map do |es|
        { name: es.skill.name, mastery: es.mastery, bonus: es.bonus }
      end
    }
  end

  # Cloner un embryon
  def clone_embryo
    embryo = current_user.embryos.find(params[:embryo_id])
    target_tube = params[:target_tube].to_i

    # Vérifier les ressources (100 crédits + 3 matières organiques)
    if current_user.credits < 100
      render json: { success: false, error: "Crédits insuffisants (100 requis)." }, status: :unprocessable_entity
      return
    end

    matiere = get_user_inventory("Matière organique")
    if matiere.nil? || matiere.quantity < 3
      render json: { success: false, error: "Matière organique insuffisante (3 requises)." }, status: :unprocessable_entity
      return
    end

    # Consommer les ressources
    current_user.decrement!(:credits, 100)
    matiere.decrement!(:quantity, 3)

    result = embryo.clone!(target_tube)

    render json: result.merge(
      new_credits: current_user.credits,
      new_matiere: matiere.quantity
    )
  end

  # Accélérer la gestation
  def accelerate_gestation
    embryo = current_user.embryos.find(params[:embryo_id])

    # Vérifier les ressources (500 crédits + 1 matière organique)
    if current_user.credits < 500
      render json: { success: false, error: "Crédits insuffisants (500 requis)." }, status: :unprocessable_entity
      return
    end

    matiere = get_user_inventory("Matière organique")
    if matiere.nil? || matiere.quantity < 1
      render json: { success: false, error: "Matière organique insuffisante (1 requise)." }, status: :unprocessable_entity
      return
    end

    # Consommer les ressources
    current_user.decrement!(:credits, 500)
    matiere.decrement!(:quantity, 1)

    result = embryo.accelerate_gestation!

    render json: {
      success: true,
      message: "Gestation accélérée ! La créature est prête.",
      new_credits: current_user.credits,
      new_matiere: matiere.quantity
    }
  end

  # Faire naître la créature (convertir en Pet)
  def birth_creature
    embryo = current_user.embryos.find(params[:embryo_id])

    unless embryo.status == 'éclos'
      render json: { success: false, error: "L'embryon n'est pas prêt à naître." }, status: :unprocessable_entity
      return
    end

    pet = embryo.convert_to_pet!

    if pet
      render json: {
        success: true,
        message: "#{pet.name} est né ! Vous pouvez le retrouver dans le bestiaire.",
        pet: {
          id: pet.id,
          name: pet.name,
          race: pet.race
        }
      }
    else
      render json: { success: false, error: "Erreur lors de la naissance." }, status: :unprocessable_entity
    end
  end

  def clonage
  end

  def stats
    @genetic_stats = GeneticStatistic.for_user(current_user)
    @total_embryos = current_user.embryos.count
    @embryos_stockes = current_user.embryos.where(status: 'stocké', modified: false).count
    @embryos_modifies = current_user.embryos.where(modified: true, status: 'stocké').count
    @embryos_en_gestation = current_user.embryos.where(status: 'en_gestation').count
    @embryos_eclos = current_user.embryos.where(status: 'éclos').count
    @genes_debloques = current_user.user_genes.where('level > 0').count
    @genes_total = Gene.where(positive: true).count
    @creatures_creees = Pet.where(creature: true, origin_embryo_id: current_user.embryos.pluck(:id)).count
  end
  
  private

  def get_inventory_quantity(item_name)
    current_user.user_inventory_objects.joins(:inventory_object)
               .find_by(inventory_objects: { name: item_name })&.quantity || 0
  end

  def get_user_inventory(item_name)
    current_user.user_inventory_objects.joins(:inventory_object)
               .find_by(inventory_objects: { name: item_name })
  end

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

  def embryo_params
    params.require(:embryo).permit(:name, :creature_type, :race, :gender)
  end

  def verify_bio_savant
    unless current_user.classe_perso.name == "Bio-savant"
      redirect_to root_path, alert: "Accès réservé aux Bio-savants."
    end
  end
end