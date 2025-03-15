class PetStatus < ApplicationRecord
  belongs_to :pet
  belongs_to :status
end
