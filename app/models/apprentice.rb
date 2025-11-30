class Apprentice < ApplicationRecord
  belongs_to :user
  belongs_to :pet

  has_many :apprentice_caracs, dependent: :destroy
  has_many :caracs, through: :apprentice_caracs
  has_many :apprentice_skills, dependent: :destroy
  has_many :skills, through: :apprentice_skills
  has_one :light_saber, dependent: :destroy

  validates :jedi_name, presence: true
  validates :side, numericality: { only_integer: true, greater_than_or_equal_to: -100, less_than_or_equal_to: 100 }
  validates :speciality, inclusion: { in: %w[Commun Gardien Consulaire Sentinelle] }
  validates :midi_chlorians, numericality: { only_integer: true, greater_than_or_equal_to: 5000, less_than_or_equal_to: 20000 }
  validates :dark_side_points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :fatigue, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Constantes pour l'entraînement
  MIN_FATIGUE_COST = 10
  MAX_FATIGUE_COST = 40
  MIN_FATIGUE_TO_TRAIN = 10 # Fatigue minimale requise pour s'entraîner
  
  # Compétences de Force (règles spéciales d'entraînement)
  FORCE_SKILLS = ["Contrôle", "Sens", "Altération"].freeze
  FORCE_SKILL_FATIGUE_MULTIPLIER = 2 # Coût en fatigue x2 pour les skills de Force
  
  # Compétences non entraînables
  NON_TRAINABLE_SKILLS = ["Résistance Corporelle"].freeze

  SPECIALITIES = %w[Commun Gardien Consulaire Sentinelle].freeze
  SABER_STYLES = [
    "Forme I - Shii-Cho",
    "Forme II - Makashi",
    "Forme III - Soresu",
    "Forme IV - Ataru",
    "Forme V - Shien/Djem So",
    "Forme VI - Niman",
    "Forme VII - Juyo/Vaapad"
  ].freeze

  # Calcule l'inclinaison vers le côté obscur ou lumineux
  def force_alignment
    if side > 30
      "Côté Lumineux"
    elsif side < -30
      "Côté Obscur"
    else
      "Équilibre"
    end
  end

  def alignment_color
    case force_alignment
    when "Côté Lumineux" then "#4FC3F7"
    when "Côté Obscur" then "#E53935"
    else "#FFD54F"
    end
  end

  # Potentiel basé sur les midi-chloriens
  def midi_chlorian_potential
    case midi_chlorians
    when 15000..20000 then "Exceptionnel"
    when 10000..14999 then "Élevé"
    when 7500..9999 then "Bon"
    else "Modeste"
    end
  end

  # Initialise les caractéristiques de l'apprenti avec les valeurs de base
  def initialize_caracs(carac_values = {})
    Carac.all.each do |carac|
      apprentice_caracs.find_or_create_by!(carac: carac) do |ac|
        ac.mastery = carac_values[carac.name.to_sym] || carac_values[carac.name] || 2
        ac.bonus = 0
      end
    end
  end

  # Initialise les compétences de l'apprenti basées sur les caractéristiques
  def initialize_skills
    # Récupérer les compétences liées aux caractéristiques
    skills_with_carac = Skill.where.not(carac_id: nil)

    skills_with_carac.each do |skill|
      apprentice_carac = apprentice_caracs.find_by(carac: skill.carac)
      base_mastery = apprentice_carac&.mastery || 0

      apprentice_skills.find_or_create_by!(skill: skill) do |as|
        as.mastery = base_mastery
        as.bonus = 0
      end
    end

    # Ajouter les compétences spéciales (sans carac associée) utiles pour un Jedi
    special_skills = ["Résistance Corporelle", "Contrôle", "Sens", "Altération"]
    special_skills.each do |skill_name|
      skill = Skill.find_by(name: skill_name)
      next unless skill

      apprentice_skills.find_or_create_by!(skill: skill) do |as|
        as.mastery = 0
        as.bonus = 0
      end
    end
  end

  # Récupère une compétence par son nom
  def skill(name)
    apprentice_skills.includes(:skill).find_by(skills: { name: name })
  end

  # Récupère une caractéristique par son nom
  def carac(name)
    apprentice_caracs.includes(:carac).find_by(caracs: { name: name })
  end

  # Grouper les compétences par caractéristique
  def grouped_skills
    apprentice_skills.includes(skill: :carac).group_by { |as| as.skill.carac&.name || "Spécial" }
  end

  # Les informations du pet associé
  delegate :name, to: :pet, prefix: true
  delegate :race, to: :pet, prefix: true
  delegate :image, to: :pet, prefix: true, allow_nil: true

  # ============================================
  # SYSTÈME D'ENTRAÎNEMENT
  # ============================================

  # Vérifie si l'apprenti peut s'entraîner (fatigue suffisante)
  def can_train?
    fatigue >= MIN_FATIGUE_TO_TRAIN
  end

  # Vérifie si une compétence est une compétence de Force
  def force_skill?(skill_name)
    FORCE_SKILLS.include?(skill_name)
  end

  # Vérifie si une compétence est entraînable
  def trainable_skill?(skill_name)
    !NON_TRAINABLE_SKILLS.include?(skill_name)
  end

  # Récupère la mastery du maître sur une compétence donnée
  def master_skill_mastery(skill_name)
    skill = Skill.find_by(name: skill_name)
    return 0 unless skill
    
    user_skill = user.user_skills.find_by(skill: skill)
    user_skill&.mastery || 0
  end

  # Vérifie si l'apprenti peut entraîner une compétence de Force
  # (ne peut pas dépasser la mastery du maître)
  def can_train_force_skill?(apprentice_skill)
    return true unless force_skill?(apprentice_skill.skill.name)
    
    master_mastery = master_skill_mastery(apprentice_skill.skill.name)
    apprentice_skill.mastery < master_mastery
  end

  # Calcule le taux de réussite basé sur la mastery actuelle (sans modificateur de talent)
  # mastery 1 = 90%, mastery 2 = 80%, ... jusqu'à minimum 10%
  def base_training_success_rate(mastery)
    rate = 100 - (mastery * 10)
    [rate, 10].max # Minimum 10%
  end

  # Calcule le taux de réussite avec le modificateur de talent
  def training_success_rate(apprentice_skill)
    base_rate = base_training_success_rate(apprentice_skill.mastery)
    modifier = apprentice_skill.success_modifier
    # Applique le modificateur et garde entre 5% et 95%
    [[base_rate + modifier, 95].min, 5].max
  end

  # Entraîne une compétence spécifique
  # Retourne un hash avec le résultat de l'entraînement
  def train_skill(skill_id)
    apprentice_skill = apprentice_skills.find_by(skill_id: skill_id)

    return { success: false, message: "Compétence introuvable." } unless apprentice_skill

    skill_name = apprentice_skill.skill.name
    is_force_skill = force_skill?(skill_name)

    # Vérifier si la compétence est entraînable
    unless trainable_skill?(skill_name)
      return { 
        success: false, 
        message: "#{skill_name} ne peut pas être entraînée. Cette compétence s'améliore uniquement par d'autres moyens.",
        non_trainable: true
      }
    end

    unless can_train?
      return { 
        success: false, 
        message: "#{jedi_name} est trop fatigué pour s'entraîner. (Fatigue: #{fatigue}/100)" 
      }
    end

    # Règle spéciale pour les compétences de Force : ne peut pas dépasser le maître
    if is_force_skill && !can_train_force_skill?(apprentice_skill)
      master_mastery = master_skill_mastery(skill_name)
      return { 
        success: false, 
        message: "#{jedi_name} ne peut pas progresser davantage en #{skill_name}. Sa maîtrise (#{apprentice_skill.mastery}D) a atteint celle de son Maître (#{master_mastery}D). L'élève ne peut surpasser le maître... pas encore.",
        is_force_skill: true,
        blocked_by_master: true
      }
    end

    # Découverte du talent lors du premier entraînement
    first_training = !apprentice_skill.talent_discovered?
    talent_discovered = nil
    if first_training
      talent_discovered = apprentice_skill.discover_talent!
    end

    # Calculer le coût en fatigue (10-40 aléatoire)
    # Les compétences de Force coûtent 2x plus de fatigue
    base_fatigue_cost = rand(MIN_FATIGUE_COST..MAX_FATIGUE_COST)
    fatigue_cost = is_force_skill ? base_fatigue_cost * FORCE_SKILL_FATIGUE_MULTIPLIER : base_fatigue_cost
    
    # Calculer le taux de réussite avec modificateur de talent
    success_rate = training_success_rate(apprentice_skill)
    roll = rand(1..100)
    training_succeeded = roll <= success_rate

    # Appliquer le coût en fatigue dans tous les cas
    new_fatigue = [fatigue - fatigue_cost, 0].max
    update!(fatigue: new_fatigue)

    result_base = {
      success: true,
      skill_name: apprentice_skill.skill.name,
      fatigue_cost: fatigue_cost,
      current_fatigue: new_fatigue,
      roll: roll,
      success_rate: success_rate,
      talent: apprentice_skill.talent,
      talent_label: apprentice_skill.talent_label,
      first_training: first_training,
      talent_discovered: talent_discovered,
      is_force_skill: is_force_skill
    }

    if training_succeeded
      # L'entraînement réussit : augmenter les stats
      old_mastery = apprentice_skill.mastery
      old_bonus = apprentice_skill.bonus
      old_display = apprentice_skill.display_value

      # Déterminer le bonus gagné (1 ou 2) en fonction du talent
      bonus_gained = determine_bonus_gained(apprentice_skill)

      # Appliquer la progression
      new_bonus = apprentice_skill.bonus + bonus_gained
      new_mastery = apprentice_skill.mastery

      # Gestion du passage au niveau supérieur
      while new_bonus > 2
        new_mastery += 1
        new_bonus -= 3
      end

      apprentice_skill.update!(mastery: new_mastery, bonus: new_bonus)
      new_display = apprentice_skill.display_value

      result_base.merge(
        training_success: true,
        old_value: old_display,
        new_value: new_display,
        bonus_gained: bonus_gained,
        message: build_success_message(apprentice_skill, old_display, new_display, bonus_gained, first_training, talent_discovered)
      )
    else
      # L'entraînement échoue
      result_base.merge(
        training_success: false,
        message: build_failure_message(apprentice_skill, first_training, talent_discovered)
      )
    end
  end

  private

  # Détermine si l'apprenti gagne +1 ou +2 de bonus
  def determine_bonus_gained(apprentice_skill)
    double_chance = apprentice_skill.double_bonus_chance
    
    if double_chance >= 100
      # Génial : toujours +2
      2
    elsif double_chance > 0
      # Talentueux : 50% de chance de +2
      rand(1..100) <= double_chance ? 2 : 1
    else
      # Ordinaire ou sous-doué : toujours +1
      1
    end
  end

  # Construit le message de succès
  def build_success_message(apprentice_skill, old_value, new_value, bonus_gained, first_training, talent_discovered)
    messages = []
    
    if first_training && talent_discovered
      talent_info = ApprenticeSkill::TALENTS[talent_discovered]
      messages << "🎯 Talent découvert : #{talent_info[:label]} !"
      
      # Ajouter la citation de l'apprenti si ce n'est pas ordinaire
      if apprentice_skill.has_talent_quote?
        quote = apprentice_skill.talent_discovery_quote
        messages << "💬 \"#{quote}\"" if quote
      end
    end
    
    if bonus_gained == 2
      messages << "💫 Entraînement exceptionnel ! #{apprentice_skill.skill.name} passe de #{old_value} à #{new_value}. (+2)"
    else
      messages << "✅ Entraînement réussi ! #{apprentice_skill.skill.name} passe de #{old_value} à #{new_value}."
    end
    
    messages.join(" ")
  end

  # Construit le message d'échec
  def build_failure_message(apprentice_skill, first_training, talent_discovered)
    messages = []
    
    if first_training && talent_discovered
      talent_info = ApprenticeSkill::TALENTS[talent_discovered]
      messages << "🎯 Talent découvert : #{talent_info[:label]} !"
      
      # Ajouter la citation de l'apprenti si ce n'est pas ordinaire
      if apprentice_skill.has_talent_quote?
        quote = apprentice_skill.talent_discovery_quote
        messages << "💬 \"#{quote}\"" if quote
      end
    end
    
    messages << "❌ L'entraînement a échoué. #{jedi_name} a fait de son mieux mais n'a pas progressé."
    
    messages.join(" ")
  end

  public

  # Description de l'état de fatigue
  def fatigue_description
    case fatigue
    when 80..100 then "En pleine forme"
    when 60..79 then "Légèrement fatigué"
    when 40..59 then "Fatigué"
    when 20..39 then "Très fatigué"
    when 1..19 then "Épuisé"
    else "Exténué"
    end
  end

  # Couleur de la barre de fatigue
  def fatigue_color
    case fatigue
    when 70..100 then "#28a745" # Vert
    when 40..69 then "#ffc107" # Jaune
    when 20..39 then "#fd7e14" # Orange
    else "#dc3545" # Rouge
    end
  end

  # Restaure la fatigue (utilisé par le MJ)
  def restore_fatigue(amount)
    new_fatigue = [fatigue + amount, 100].min
    update!(fatigue: new_fatigue)
    new_fatigue
  end

  # Restaure complètement la fatigue
  def full_rest!
    update!(fatigue: 100)
  end
end
