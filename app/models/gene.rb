class Gene < ApplicationRecord
  has_many :user_genes, dependent: :destroy
  has_many :users, through: :user_genes
  
  enum category: {
    defensif: 0,
    offensif: 1,
    dexterite: 2,
    deplacement: 3,
    perception: 4,
    social: 5,
    adaptation: 6,
    psychique: 7,
    insolite: 8,
    esthetique: 9
  }
end
