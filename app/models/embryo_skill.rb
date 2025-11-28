class EmbryoSkill < ApplicationRecord
  belongs_to :embryo
  belongs_to :skill

  validates :mastery, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :bonus, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :embryo_id, uniqueness: { scope: :skill_id, message: "Ce skill est déjà associé à cet embryon" }
end

