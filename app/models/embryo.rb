class Embryo < ApplicationRecord
  belongs_to :user
  has_many :embryo_skills, dependent: :destroy
  has_many :skills, through: :embryo_skills

  validates :name, presence: true, length: { maximum: 30 }
  validates :creature_type, presence: true
  validates :status, inclusion: { in: %w[stocké en_culture en_gestation éclos], message: "%{value} n'est pas un statut valide." }

  CREATURE_TYPES = YAML.load_file(Rails.root.join('config', 'catalogs', 'creature_types.yml'))

  # Constantes pour les statuts
  STATUSES = %w[stocké en_culture en_gestation éclos].freeze

  after_create :assign_default_skills

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

  private

  def assign_default_skills
    stats = creature_stats
    return if stats.blank?

    # Créer les skills de base avec les valeurs du creature_type
    skill_mappings = {
      'Résistance Corporelle' => stats['res_corp'],
      'Précision' => stats['precision'],
      'Vitesse' => stats['vitesse'],
      'Esquive' => stats['esquive']
    }

    skill_mappings.each do |skill_name, value|
      skill = Skill.find_by(name: skill_name)
      next unless skill && value

      embryo_skills.create!(
        skill: skill,
        mastery: value,
        bonus: 0
      )
    end
  end
end

