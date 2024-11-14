class ClassePerso < ApplicationRecord
    has_many :users, dependent: :destroy
end
