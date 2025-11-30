class ApprenticeCarac < ApplicationRecord
  belongs_to :apprentice
  belongs_to :carac

  validates :mastery, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 15 }
  validates :bonus, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 15 }
  validates :carac_id, uniqueness: { scope: :apprentice_id }
end

