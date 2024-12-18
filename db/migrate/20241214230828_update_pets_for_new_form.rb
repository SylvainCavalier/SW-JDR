class UpdatePetsForNewForm < ActiveRecord::Migration[7.0]
  def change
    # Modifier les colonnes existantes avec conversion explicite
    change_column :pets, :damage_1, :integer, using: 'damage_1::integer'
    change_column :pets, :damage_2, :integer, using: 'damage_2::integer'

    # Ajouter les nouvelles colonnes
    add_column :pets, :damage_1_bonus, :integer, default: 0, null: false
    add_column :pets, :damage_2_bonus, :integer, default: 0, null: false
  end
end