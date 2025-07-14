class UserGene < ApplicationRecord
  belongs_to :user
  belongs_to :gene

  validates :level, inclusion: { in: 1..3 }
end
