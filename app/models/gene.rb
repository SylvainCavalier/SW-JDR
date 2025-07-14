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
    psychique: 6,
    insolite: 7,
    esthetique: 8
  }
end
