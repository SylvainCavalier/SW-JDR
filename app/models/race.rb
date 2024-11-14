class Race < ApplicationRecord
    has_many :users, dependent: :destroy
end
