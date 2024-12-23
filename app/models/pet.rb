class Pet < ApplicationRecord
  has_many :pet_inventory_objects, dependent: :destroy
  has_many :inventory_objects, through: :pet_inventory_objects
  has_many :pet_skills, dependent: :destroy
  has_many :skills, through: :pet_skills
  has_one_attached :image

  belongs_to :status, optional: true
  belongs_to :user, foreign_key: :id, primary_key: :pet_id, optional: true

  validates :name, presence: true, length: { maximum: 20 }
  validates :race, presence: true, length: { maximum: 12 }
  validates :category, inclusion: { in: %w[animal droïde bio-armure humanoïde], message: "%{value} n'est pas une catégorie valide." }
  validates :hp_max, numericality: { only_integer: true, greater_than: 0 }
  validates :hp_current, numericality: { greater_than_or_equal_to: -20 }
  validates :damage_1, :damage_2, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :damage_1_bonus, :damage_2_bonus, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :size, numericality: { greater_than: 0, less_than_or_equal_to: 1000, message: "La taille doit être comprise entre 0 et 10 mètres." }
  validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 500, message: "Le poids doit être compris entre 1 et 500 kg." }

  after_commit :resize_image_if_needed
  after_initialize :set_default_values, if: :new_record?
  after_update :reset_hunger_for_special_categories

  def hunger_description
    ["Paralysé par la faim", "Affamé", "Faim", "Petit creux", "Repus"][hunger] || "Inconnu"
  end

  def fatigue_description
    ["Exténué", "Epuisé", "Fatigué", "Un peu fatigué", "En pleine forme" ][fatigue] || "Inconnu"
  end

  def mood_description
    ["Furieux", "Enervé", "Agacé", "Content", "Heureux"][mood] || "Inconnu"
  end

  def loyalty_description
    ["Traître", "Peu loyal", "Méfiant", "Loyal", "Inébranlable"][loyalty] || "Inconnu"
  end

  # Chance sur 3 pour augmenter la loyauté
  def loyalty_up
    [loyalty + 1, 4].min if rand(1..3) == 1
  end

  def check_critical_states
    if mood == 0
      update!(loyalty: [loyalty - 1, 0].max)
      Rails.logger.info "⚠️ Humeur furieuse atteinte : loyauté diminuée !"
    end

    if hunger == 0
      update!(loyalty: [loyalty - 1, 0].max)
      Rails.logger.info "⚠️ Faim paralysante atteinte : loyauté diminuée !"
    end
  end

  def random_skill_or_damage
    skill_or_damage = [
      { type: :skill, object: pet_skills.sample },
      { type: :damage, attribute: :damage_1 },
      { type: :damage, attribute: :damage_2 }
    ].sample

    skill_or_damage
  end

  # Méthodes pour les animaux
  def feed!
    update!(
      hunger: [hunger + 2, 4].min,
      loyalty: loyalty_up || loyalty
    )
    random_comment(["Il a dévoré avec appétit !", "Votre familier semble rassasié.", "Un vrai festin pour lui !"])
  end

  def cuddle!
    update!(
      mood: [mood + 2, 4].min
    )
    random_comment(["Il ronronne de bonheur.", "Votre câlin a illuminé sa journée.", "Il met ses pattes en l'air et profite."])
  end

  def play!
    return "Action impossible : faim ou fatigue insuffisante." if hunger.zero? || fatigue.zero?

    update!(
      hunger: [hunger - 1, 0].max,
      fatigue: [fatigue - 1, 4].min,
      mood: [mood + 1, 4].min,
      loyalty: loyalty_up || loyalty
    )
    random_comment(["Il a couru partout, quelle énergie !", "Votre familier semble heureux après cette séance de jeu."])
  end

  def scold!
    update!(
      mood: [mood - 2, 0].max
    )
    check_critical_states
    random_comment(["Votre familier baisse la tête, il est vexé.", "Il vous regarde avec des yeux perdus."])
  end

  def train!
    return "Action impossible : faim ou fatigue insuffisante." if hunger.zero? || fatigue.zero?
  
    message = "Aucun effet d'entraînement défini."
  
    ActiveRecord::Base.transaction do
      random_outcome = rand(1..100)
  
      case random_outcome
      when 1..50
        message = "L'entraînement a été dur ! Mais aucun bonus n'est gagné cette fois."
      when 51..60
        skill = pet_skills.joins(:skill).find_by(skills: { name: "Esquive" })
        message = update_skill_or_bonus(skill, "esquive")
      when 61..70
        skill = pet_skills.joins(:skill).find_by(skills: { name: "Vitesse" })
        message = update_skill_or_bonus(skill, "vitesse")
      when 71..80
        skill = pet_skills.joins(:skill).find_by(skills: { name: "Précision" })
        message = update_skill_or_bonus(skill, "précision")
      when 81..90
        increment!(:damage_1_bonus, 1)
        message = "L'entraînement a augmenté ses dégâts (attaque 1) de +1 !"
      when 91..100
        increment!(:damage_2_bonus, 1)
        message = "L'entraînement a augmenté ses dégâts (attaque 2) de +1 !"
      end
  
      update!(fatigue: [fatigue - 2, 4].min, loyalty: loyalty_up || loyalty)
      check_critical_states
    end
  
    random_comment([message, "Votre familier semble plus fort !"])
  rescue => e
    Rails.logger.error "Erreur pendant l'entraînement : #{e.message}"
    "L'entraînement a échoué."
  end

  # Méthodes pour les droïdes
  def oil!
    update!(
      fatigue: [fatigue + 2, 0].max,
      mood: [mood + 1, 4].min
    )
    random_comment(["Ses articulations grincent moins maintenant.", "Votre droïde semble parfaitement huilé."])
  end

  def wipe_memory!
    update!(
      loyalty: [loyalty + 2, 0].max,
      mood: [mood + 1, 0].max
    )
    random_comment(["Mémoire effacée. Il vous regarde sans trop comprendre.", "Un reset complet a été effectué."])
  end

  def upgrade!
    return "Action impossible : faim ou fatigue insuffisante." if hunger.zero? || fatigue.zero?
    return "Pas assez de crédits !" unless user && user.credits >= 300

    ActiveRecord::Base.transaction do
      # Retirer 200 crédits à l'utilisateur
      user.decrement!(:credits, 300)

      # Choisir aléatoirement un skill ou un dégât
      target = random_skill_or_damage

      case target[:type]
      when :skill
        if target[:object]
          target[:object].increment!(:bonus, 1)
          message = "Votre droïde a amélioré son #{target[:object].skill.name} de +1 !"
        else
          message = "Aucun skill trouvé à améliorer, réessayez plus tard."
        end
      when :damage
        increment!(target[:attribute], 1)
        message = "Amélioration réussie ! Ses dégâts ont augmenté de +1."
      end

      # Fatigue et loyauté
      update!(fatigue: [fatigue - 2, 4].min, loyalty: [loyalty - 1, 0].max,)

      # Notification pour l'utilisateur
      user.notifications.create!(message: "Vous avez dépensé 200 crédits pour améliorer #{name}.")
    end

    check_critical_states
    random_comment(message)
  rescue => e
    Rails.logger.error "Erreur pendant l'amélioration : #{e.message}"
    "L'amélioration a échoué en raison d'une erreur."
  end

  # Méthodes pour les humanoïdes
  def compliment!
    update!(
      mood: [mood + 2, 4].min
    )
    random_comment(["Votre compliment lui a redonné confiance.", "Il vous sourit avec reconnaissance."])
  end

  def chat!
    return "Action impossible : faim ou fatigue insuffisante." if hunger.zero? || fatigue.zero?
    update!(
      mood: [mood + 1, 4].min,
      fatigue: [fatigue - 1, 4].min,
      loyalty: loyalty_up || loyalty
    )
    check_critical_states
    random_comment(["Une bonne discussion, ça rapproche !", "Il semble plus joyeux après cette conversation."])
  end

  def hit!
    update!(
      mood: [mood - 2, 0].max,
      loyalty: [loyalty - 1, 0].max
    )
    check_critical_states
    random_comment(["Il vous fixe d'un regard noir.", "Votre coup n'a fait que creuser le fossé entre vous."])
  end

  def stat_modifiers
    modifiers = {
      accuracy: 0,
      damage: 0,
      resistance_corporelle: 0,
      vitesse: 0,
      esquive: 0
    }
  
    # Modificateurs basés sur l'humeur
    case mood
    when 4 then modifiers[:accuracy] += 1
    when 2 then modifiers[:accuracy] -= 1; modifiers[:damage] += 1
    when 1 then modifiers[:accuracy] -= 2; modifiers[:damage] += 2
    when 0 then modifiers[:accuracy] -= 3; modifiers[:damage] += 3
    end
  
    # Modificateurs basés sur la loyauté
    case loyalty
    when 4 then modifiers[:resistance_corporelle] += 1
    when 2 then apply_global_skill_modifier(modifiers, -1)  # Méfiant
    when 1 then apply_global_skill_modifier(modifiers, -2)  # Peu Loyal
    when 0 then apply_global_skill_modifier(modifiers, -3)  # Traître
    end
  
    # Modificateurs basés sur la faim
    case hunger
    when 4 then modifiers[:vitesse] -= 1
    when 2 then apply_global_skill_modifier(modifiers, -1)  # Faim
    when 1 then apply_global_skill_modifier(modifiers, -2); modifiers[:damage] -= 2  # Affamé
    when 0 then apply_global_skill_modifier(modifiers, -3); modifiers[:damage] -= 3  # Paralysé par la faim
    end
  
    # Modificateurs basés sur la fatigue
    case fatigue
    when 4 then apply_global_skill_modifier(modifiers, 1); modifiers[:damage] += 1  # En pleine forme
    when 2 then apply_global_skill_modifier(modifiers, -1); modifiers[:damage] -= 1  # Fatigué
    when 1 then apply_global_skill_modifier(modifiers, -2); modifiers[:damage] -= 2  # Épuisé
    when 0 then apply_global_skill_modifier(modifiers, -3); modifiers[:damage] -= 3  # Exténué
    end
  
    modifiers
  end

  def calculate_resistance_bonus
    resistance_skill = pet_skills.joins(:skill).find_by(skills: { name: "Résistance Corporelle" })
    if resistance_skill.nil?
      Rails.logger.warn "⚠️ Compétence 'Résistance corporelle' introuvable pour le pet #{id}."
      0
    else
      resistance_mastery = resistance_skill.mastery || 0
      roll_dice(resistance_mastery, 6) + (resistance_skill.bonus || 0)
    end
  end

  private

  def roll_dice(number, sides)
    Array.new(number) { rand(1..sides) }.sum
  end

  def resize_image_if_needed
    return unless saved_change_to_image?

    begin
      processed_variant = image.variant(resize_to_limit: [800, 800])
      processed_variant.processed
    rescue => e
      Rails.logger.error "Erreur lors du redimensionnement de l'image : #{e.message}"
    end
  end

  def saved_change_to_image?
    saved_change_to_attribute?(:image) && image.attached?
  end

  def set_default_values
    self.mood ||= 2
    self.loyalty ||= 2
    self.hunger ||= 2
    self.fatigue ||= 2
    self.status ||= Status.find_by(name: "En forme")
  end

  def random_comment(messages)
    messages.sample
  end

  def apply_global_skill_modifier(modifiers, value)
    %i[accuracy vitesse esquive].each do |skill|
      modifiers[skill] += value
    end
  end

  def reset_hunger_for_special_categories
    return if hunger == 3
  
    if %w[humanoïde droïde].include?(category)
      update!(hunger: 3)
    end
  end

  def update_skill_or_bonus(skill, skill_name)
    return "Aucun skill #{skill_name} trouvé pour ce familier." if skill.nil?
  
    if skill.bonus < 2
      skill.increment!(:bonus, 1)
      "L'entraînement a amélioré son #{skill_name} de +1 (bonus)."
    else
      skill.update!(bonus: 0, mastery: skill.mastery + 1)
      "L'entraînement a amélioré son #{skill_name} en passant à #{skill.mastery}D."
    end
  end
end
  