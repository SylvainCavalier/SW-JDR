class Embryo < ApplicationRecord
  belongs_to :user
  has_many :embryo_skills, dependent: :destroy
  has_many :skills, through: :embryo_skills

  validates :name, presence: true, length: { maximum: 30 }
  validates :creature_type, presence: true
  validates :status, inclusion: { in: %w[stocké en_culture en_gestation éclos], message: "%{value} n'est pas un statut valide." }
  validates :gestation_tube, inclusion: { in: [nil, 1, 2, 3] }

  CREATURE_TYPES = YAML.load_file(Rails.root.join('config', 'catalogs', 'creature_types.yml'))
  STATUSES = %w[stocké en_culture en_gestation éclos].freeze
  MAX_GESTATION_TUBES = 3

  # Limites des skills
  SKILL_CAPS = {
    'Résistance Corporelle' => { mastery: 5, bonus: 2 },
    'Précision' => { mastery: 7, bonus: 4 },
    'Esquive' => { mastery: 7, bonus: 4 },
    'Vitesse' => { mastery: 7, bonus: 4 }
  }.freeze

  # Limites des dégâts
  DAMAGE_CAPS = { damage: 7, damage_bonus: 4 }.freeze

  # Adjectifs pour special_traits selon le niveau
  SPECIAL_TRAIT_ADJECTIVES = {
    1 => "légère",
    2 => "développée",
    3 => "extrême"
  }.freeze

  # Coûts en fonction du nombre de gènes
  TRAIT_COSTS = {
    1 => { eprouvettes: 1, matiere: 2 },
    2 => { eprouvettes: 2, matiere: 4 },
    3 => { eprouvettes: 3, matiere: 6 }
  }.freeze

  after_create :assign_default_skills

  scope :available_for_modification, -> { where(status: 'stocké', modified: false) }
  scope :in_gestation, -> { where(status: 'en_gestation') }
  scope :modified_not_gestating, -> { where(modified: true, status: 'stocké') }

  def self.creature_type_options
    CREATURE_TYPES.keys.map { |key| [key.humanize, key] }
  end

  def creature_stats
    CREATURE_TYPES[creature_type] || {}
  end

  def skill_value(skill_name)
    embryo_skill = embryo_skills.joins(:skill).find_by(skills: { name: skill_name })
    return { mastery: 0, bonus: 0 } unless embryo_skill
    { mastery: embryo_skill.mastery, bonus: embryo_skill.bonus }
  end

  # Calcul des probabilités de réussite
  def self.calculate_probabilities(genes_with_levels)
    return { failure: 0, partial: 0, success: 0, perfect: 0 } if genes_with_levels.empty?

    num_genes = genes_with_levels.size
    total_level = genes_with_levels.sum { |g| g[:level] }
    avg_level = total_level.to_f / num_genes

    # Base probabilities ajustées selon nombre et niveau des gènes
    base_failure = 5 + (num_genes * 5) + (avg_level * 3)
    base_partial = 15 + (num_genes * 5) + (avg_level * 2)
    base_success = 60 - (num_genes * 8) - (avg_level * 4)
    base_perfect = 20 - (num_genes * 2) - (avg_level * 1)

    # Normalisation pour avoir 100%
    total = base_failure + base_partial + base_success + base_perfect
    {
      failure: [(base_failure / total * 100).round, 5].max,
      partial: [(base_partial / total * 100).round, 10].max,
      success: [(base_success / total * 100).round, 20].max,
      perfect: [(base_perfect / total * 100).round, 5].max
    }.tap do |probs|
      # Ajuster pour faire exactement 100%
      diff = 100 - probs.values.sum
      probs[:success] += diff
    end
  end

  # Application des traits génétiques
  def apply_genetic_traits!(gene_ids_with_levels, user_genes_to_consume)
    return { success: false, error: "Embryon déjà modifié" } if modified?

    # Déterminer le résultat
    probs = self.class.calculate_probabilities(gene_ids_with_levels)
    roll = rand(1..100)
    
    result_type = determine_result(roll, probs)
    
    case result_type
    when :failure
      handle_failure(user_genes_to_consume)
    when :partial
      handle_partial_success(gene_ids_with_levels, user_genes_to_consume)
    when :success
      handle_success(gene_ids_with_levels, user_genes_to_consume, bonus_multiplier: 1.0)
    when :perfect
      handle_success(gene_ids_with_levels, user_genes_to_consume, bonus_multiplier: 1.5)
    end
  end

  # Mise en gestation
  def start_gestation!
    return { success: false, error: "L'embryon n'est pas prêt pour la gestation" } unless modified? && status == 'stocké'
    
    # Trouver une cuve libre
    used_tubes = user.embryos.in_gestation.pluck(:gestation_tube).compact
    available_tube = (1..MAX_GESTATION_TUBES).find { |t| !used_tubes.include?(t) }
    
    return { success: false, error: "Toutes les cuves sont occupées" } unless available_tube

    # Durée aléatoire entre 3 et 30 jours
    days = rand(3..30)
    
    update!(
      status: 'en_gestation',
      gestation_tube: available_tube,
      gestation_started_at: Time.current,
      gestation_days_total: days,
      gestation_days_remaining: days
    )

    { success: true, tube: available_tube, days: days }
  end

  # Recyclage de l'embryon
  def recycle!
    return { success: false, error: "Impossible de recycler cet embryon" } unless can_recycle?

    # Récupérer une partie des matières organiques (50%)
    matiere_recovered = (applied_genes.size * 2 * 0.5).ceil
    
    # Ajouter les matières à l'inventaire
    matiere_item = InventoryObject.find_by(name: "Matière organique")
    if matiere_item
      user_matiere = user.user_inventory_objects.find_or_initialize_by(inventory_object: matiere_item)
      user_matiere.quantity = (user_matiere.quantity || 0) + matiere_recovered
      user_matiere.save!
    end

    # Mettre à jour les stats
    GeneticStatistic.for_user(user).increment_stat!(:embryos_recycled)

    destroy!
    { success: true, matiere_recovered: matiere_recovered }
  end

  def can_recycle?
    modified? && status == 'stocké'
  end

  # Avancer la gestation d'un jour
  def advance_gestation!(days = 1)
    return unless status == 'en_gestation' && gestation_days_remaining.present?

    new_remaining = [gestation_days_remaining - days, 0].max
    update!(gestation_days_remaining: new_remaining)

    complete_gestation! if new_remaining.zero?
  end

  # Accélérer la gestation (à terme immédiat)
  def accelerate_gestation!
    return { success: false, error: "Pas en gestation" } unless status == 'en_gestation'

    update!(gestation_days_remaining: 0)
    complete_gestation!
  end

  # Cloner l'embryon
  def clone!(target_tube)
    return { success: false, error: "Embryon non clonable" } unless status == 'en_gestation'
    return { success: false, error: "Cuve occupée" } if user.embryos.in_gestation.exists?(gestation_tube: target_tube)

    # 50% de chance de réussite
    if rand < 0.5
      clone = user.embryos.create!(
        name: "#{name} (Clone)",
        creature_type: creature_type,
        race: race,
        gender: gender,
        status: 'en_gestation',
        weapon: weapon,
        damage_1: damage_1,
        damage_bonus_1: damage_bonus_1,
        special_traits: special_traits,
        force: force,
        size: size,
        weight: weight,
        hp_max: hp_max,
        modified: true,
        applied_genes: applied_genes,
        final_stats: final_stats,
        gestation_tube: target_tube,
        gestation_started_at: Time.current,
        gestation_days_total: gestation_days_total,
        gestation_days_remaining: gestation_days_remaining
      )

      # Copier les skills
      embryo_skills.each do |es|
        clone.embryo_skills.create!(skill: es.skill, mastery: es.mastery, bonus: es.bonus)
      end

      GeneticStatistic.for_user(user).increment_stat!(:clones_created)
      { success: true, clone: clone }
    else
      GeneticStatistic.for_user(user).increment_stat!(:clones_failed)
      { success: false, error: "Le clonage a échoué" }
    end
  end

  # Convertir en Pet à la fin de la gestation
  def convert_to_pet!
    return nil unless status == 'éclos'

    stats = final_stats.presence || {}
    
    pet = Pet.create!(
      name: name,
      race: race || creature_type.humanize,
      category: 'animal',
      hp_max: stats['hp_max'] || hp_max,
      hp_current: stats['hp_max'] || hp_max,
      damage_1: stats['damage_1'] || damage_1,
      damage_1_bonus: stats['damage_bonus_1'] || damage_bonus_1,
      damage_2: 0,
      damage_2_bonus: 0,
      weapon_1: weapon,
      weapon_2: nil,
      size: size,
      weight: weight,
      creature: true,
      force: force || false,
      special_traits: special_traits,
      origin_embryo_id: id,
      vitesse: stats.dig('skills', 'Vitesse', 'mastery') || skill_value('Vitesse')[:mastery]
    )

    # Créer les pet_skills
    embryo_skills.each do |es|
      pet.pet_skills.create!(
        skill: es.skill,
        mastery: es.mastery,
        bonus: es.bonus
      )
    end

    GeneticStatistic.for_user(user).increment_stat!(:gestations_completed)
    pet
  end

  private

  def assign_default_skills
    stats = creature_stats
    return if stats.blank?

    skill_mappings = {
      'Résistance Corporelle' => stats['res_corp'],
      'Précision' => stats['precision'],
      'Vitesse' => stats['vitesse'],
      'Esquive' => stats['esquive']
    }

    skill_mappings.each do |skill_name, value|
      skill = Skill.find_by(name: skill_name)
      next unless skill && value
      embryo_skills.create!(skill: skill, mastery: value, bonus: 0)
    end
  end

  def determine_result(roll, probs)
    cumulative = 0
    cumulative += probs[:failure]
    return :failure if roll <= cumulative

    cumulative += probs[:partial]
    return :partial if roll <= cumulative

    cumulative += probs[:success]
    return :success if roll <= cumulative

    :perfect
  end

  def handle_failure(_user_genes_to_consume)
    # Échec total : l'embryon est détruit, les matériaux sont perdus
    # Les gènes ne sont PAS consommés (ce sont des découvertes permanentes)
    GeneticStatistic.for_user(user).increment_stat!(:traits_applications_failed)
    
    # Détruire l'embryon
    destroy!
    
    { 
      success: false, 
      result_type: :failure, 
      message: "L'application des traits a échoué. L'embryon et les matériaux ont été perdus." 
    }
  end

  def handle_partial_success(gene_ids_with_levels, _user_genes_to_consume)
    # Les gènes ne sont PAS consommés
    
    # Créature faible - appliquer seulement une partie des bonus avec malus
    apply_genes_to_stats(gene_ids_with_levels, multiplier: 0.3, add_random: false)
    
    update!(modified: true, applied_genes: gene_ids_with_levels)
    GeneticStatistic.for_user(user).increment_stat!(:traits_applications_partial)
    
    {
      success: true,
      result_type: :partial,
      message: "Réussite partielle ! La créature est viable mais affaiblie.",
      embryo: reload_with_skills
    }
  end

  def handle_success(gene_ids_with_levels, _user_genes_to_consume, bonus_multiplier:)
    # Les gènes ne sont PAS consommés
    
    apply_genes_to_stats(gene_ids_with_levels, multiplier: bonus_multiplier, add_random: true)
    
    update!(modified: true, applied_genes: gene_ids_with_levels)
    
    stat_key = bonus_multiplier > 1.0 ? :traits_applications_success : :traits_applications_success
    GeneticStatistic.for_user(user).increment_stat!(stat_key)
    
    {
      success: true,
      result_type: bonus_multiplier > 1.0 ? :perfect : :success,
      message: bonus_multiplier > 1.0 ? "Réussite parfaite ! La créature est exceptionnelle !" : "Réussite ! La créature est viable.",
      embryo: reload_with_skills
    }
  end

  def apply_genes_to_stats(gene_ids_with_levels, multiplier:, add_random:)
    genes_data = gene_ids_with_levels.map do |g|
      { gene: Gene.find(g[:gene_id]), level: g[:level] }
    end

    new_special_traits = special_traits || []
    final_stats_data = {
      'hp_max' => hp_max,
      'damage_1' => damage_1,
      'damage_bonus_1' => damage_bonus_1,
      'skills' => {}
    }

    # Déterminer le type de résultat pour l'aléatoire
    is_perfect = add_random && multiplier > 1.0
    is_success = add_random && multiplier <= 1.0
    is_partial = !add_random && multiplier < 1.0

    # Appliquer des bonus/malus aléatoires de base selon le résultat
    if is_perfect
      # RÉUSSITE PARFAITE : Variation aléatoire très positive
      # PV : -3 à +6
      hp_variation = rand(-3..6)
      new_hp = [hp_max + hp_variation, 1].max
      update!(hp_max: new_hp)
      final_stats_data['hp_max'] = new_hp

      # Skills : mastery 0 à +1, bonus 0 à +2
      embryo_skills.each do |es|
        caps = SKILL_CAPS[es.skill.name] || { mastery: 7, bonus: 4 }
        random_mastery = rand(0..1)
        random_bonus = rand(0..2)
        
        new_mastery = [es.mastery + random_mastery, caps[:mastery]].min
        new_bonus = [es.bonus + random_bonus, caps[:bonus]].min
        
        es.update!(mastery: new_mastery, bonus: new_bonus)
        final_stats_data['skills'][es.skill.name] = { 'mastery' => new_mastery, 'bonus' => new_bonus }
      end

      # Damage : mastery +1 à +2, bonus +1 à +3
      random_damage = rand(1..2)
      random_damage_bonus = rand(1..3)
      new_dmg = [damage_1 + random_damage, DAMAGE_CAPS[:damage]].min
      new_dmg_bonus = [damage_bonus_1 + random_damage_bonus, DAMAGE_CAPS[:damage_bonus]].min
      update!(damage_1: new_dmg, damage_bonus_1: new_dmg_bonus)
      final_stats_data['damage_1'] = new_dmg
      final_stats_data['damage_bonus_1'] = new_dmg_bonus

    elsif is_success
      # RÉUSSITE : Variation aléatoire positive
      # PV : -3 à +6
      hp_variation = rand(-3..6)
      new_hp = [hp_max + hp_variation, 1].max
      update!(hp_max: new_hp)
      final_stats_data['hp_max'] = new_hp

      # Skills : mastery 0 à +1, bonus 0 à +2
      embryo_skills.each do |es|
        caps = SKILL_CAPS[es.skill.name] || { mastery: 7, bonus: 4 }
        random_mastery = rand(0..1)
        random_bonus = rand(0..2)
        
        new_mastery = [es.mastery + random_mastery, caps[:mastery]].min
        new_bonus = [es.bonus + random_bonus, caps[:bonus]].min
        
        es.update!(mastery: new_mastery, bonus: new_bonus)
        final_stats_data['skills'][es.skill.name] = { 'mastery' => new_mastery, 'bonus' => new_bonus }
      end

      # Damage : mastery 0 à +1, bonus 0 à +2
      random_damage = rand(0..1)
      random_damage_bonus = rand(0..2)
      new_dmg = [damage_1 + random_damage, DAMAGE_CAPS[:damage]].min
      new_dmg_bonus = [damage_bonus_1 + random_damage_bonus, DAMAGE_CAPS[:damage_bonus]].min
      update!(damage_1: new_dmg, damage_bonus_1: new_dmg_bonus)
      final_stats_data['damage_1'] = new_dmg
      final_stats_data['damage_bonus_1'] = new_dmg_bonus

    elsif is_partial
      # ÉCHEC PARTIEL : Variation aléatoire négative (créature faible)
      # PV : -5 à -1
      hp_variation = rand(-5..-1)
      new_hp = [hp_max + hp_variation, 1].max
      update!(hp_max: new_hp)
      final_stats_data['hp_max'] = new_hp

      # Skills : mastery -1 à 0, bonus -2 à 0
      embryo_skills.each do |es|
        random_mastery = rand(-1..0)
        random_bonus = rand(-2..0)
        
        new_mastery = [es.mastery + random_mastery, 0].max
        new_bonus = [es.bonus + random_bonus, 0].max
        
        es.update!(mastery: new_mastery, bonus: new_bonus)
        final_stats_data['skills'][es.skill.name] = { 'mastery' => new_mastery, 'bonus' => new_bonus }
      end

      # Damage : mastery -1 à 0, bonus -1 à +1
      random_damage = rand(-1..0)
      random_damage_bonus = rand(-1..1)
      new_dmg = [damage_1 + random_damage, 0].max
      new_dmg_bonus = [damage_bonus_1 + random_damage_bonus, 0].max
      update!(damage_1: new_dmg, damage_bonus_1: new_dmg_bonus)
      final_stats_data['damage_1'] = new_dmg
      final_stats_data['damage_bonus_1'] = new_dmg_bonus
    end

    genes_data.each do |gene_data|
      gene = gene_data[:gene]
      level = gene_data[:level]

      # Appliquer skill_bonuses (bonus fixe du gène, l'aléatoire est déjà appliqué en base)
      gene.skill_bonuses.each do |skill_key, _|
        skill_name = skill_key_to_name(skill_key)
        next unless skill_name

        embryo_skill = embryo_skills.joins(:skill).find_by(skills: { name: skill_name })
        next unless embryo_skill

        bonus_mastery = (level * multiplier).ceil
        caps = SKILL_CAPS[skill_name] || { mastery: 7, bonus: 4 }
        new_mastery = [embryo_skill.mastery + bonus_mastery, caps[:mastery]].min
        embryo_skill.update!(mastery: new_mastery)

        final_stats_data['skills'][skill_name] = { 'mastery' => new_mastery, 'bonus' => embryo_skill.bonus }
      end

      # Appliquer stats_bonuses (bonus fixe du gène, l'aléatoire est déjà appliqué en base)
      gene.stats_bonuses.each do |stat_key, value|
        next unless value

        case stat_key
        when 'hp_max'
          bonus = (level * 2 * multiplier).ceil
          new_hp = [hp_max + bonus, 1].max
          update!(hp_max: new_hp)
          final_stats_data['hp_max'] = new_hp
        when 'damage'
          bonus = (level * multiplier).ceil
          new_dmg = [damage_1 + bonus, DAMAGE_CAPS[:damage]].min
          update!(damage_1: new_dmg)
          final_stats_data['damage_1'] = new_dmg
        when 'damage_bonus'
          bonus = (level * multiplier).ceil
          new_dmg_bonus = [damage_bonus_1 + bonus, DAMAGE_CAPS[:damage_bonus]].min
          update!(damage_bonus_1: new_dmg_bonus)
          final_stats_data['damage_bonus_1'] = new_dmg_bonus
        when 'force'
          update!(force: true) if level >= 2
        end
      end

      # Appliquer special_traits
      gene.special_traits.each do |trait|
        adjective = SPECIAL_TRAIT_ADJECTIVES[level] || "légère"
        trait_name = trait['base'] || trait.to_s
        
        if trait['type'] == 'adjective'
          new_special_traits << "#{trait_name} #{adjective}"
        elsif trait['type'] == 'bonus' && trait['values']
          bonus_value = trait['values'][level.to_s] || trait['values']['1']
          new_special_traits << "#{trait_name}: #{bonus_value}"
        else
          new_special_traits << trait_name
        end
      end
    end

    update!(special_traits: new_special_traits.uniq, final_stats: final_stats_data)
  end

  def skill_key_to_name(key)
    {
      'res_corp' => 'Résistance Corporelle',
      'precision' => 'Précision',
      'vitesse' => 'Vitesse',
      'esquive' => 'Esquive'
    }[key.to_s]
  end

  def reload_with_skills
    reload # Recharger depuis la base de données
    {
      id: id,
      name: name,
      creature_type: creature_type,
      race: race,
      gender: gender,
      hp_max: hp_max,
      damage_1: damage_1,
      damage_bonus_1: damage_bonus_1,
      weapon: weapon,
      special_traits: special_traits,
      status: status,
      modified: modified,
      skills: embryo_skills.reload.includes(:skill).map do |es|
        { name: es.skill.name, mastery: es.mastery, bonus: es.bonus }
      end
    }
  end

  def complete_gestation!
    update!(status: 'éclos', gestation_tube: nil)
  end
end
