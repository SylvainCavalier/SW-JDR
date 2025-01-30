class Sphero < ApplicationRecord
  belongs_to :user
  has_many :sphero_skills, dependent: :destroy
  has_many :skills, through: :sphero_skills

  validates :category, inclusion: { in: %w(attaque protection survie) }
  validates :quality, inclusion: { in: 1..3 }
  validates :medipacks, numericality: { less_than_or_equal_to: 5, message: "ne peut pas dépasser 5." }

  after_create :initialize_sphero_attributes

  private

  def initialize_sphero_attributes
    self.hp_max = 20
    self.hp_current = 20
    self.shield_current = case category
                          when 'protection'
                            { 1 => 30, 2 => 40, 3 => 50 }[quality]
                          else
                            0
    end
    self.shield_max = case category
                      when 'protection'
                        { 1 => 30, 2 => 40, 3 => 50 }[quality]
                      else
                        0
                      end
    self.medipacks = category == 'survie' ? 3 : 0
    save!
    assign_default_skills
  end

  def assign_default_skills
    esquive = Skill.find_or_create_by(name: 'Esquive')
    resistance = Skill.find_or_create_by(name: 'Résistance Corporelle')
    sphero_skills.create!(skill: esquive, mastery: 6)
    sphero_skills.create!(skill: resistance, mastery: 2)

    case category
    when 'attaque'
      tir = Skill.find_or_create_by(name: 'Tir')
      sphero_skills.create!(skill: tir, mastery: 4 + quality, bonus: quality + 2)
    when 'protection'
      habilete = Skill.find_or_create_by(name: 'Habileté')
      sphero_skills.create!(skill: habilete, mastery: 4 + quality)
    when 'survie'
      medecine = Skill.find_or_create_by(name: 'Médecine')
      sphero_skills.create!(skill: medecine, mastery: 4 + quality)
    end
  end
end
