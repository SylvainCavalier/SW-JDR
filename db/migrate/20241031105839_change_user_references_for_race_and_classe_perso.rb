class ChangeUserReferencesForRaceAndClassePerso < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :race, :string
    remove_column :users, :class_name, :string
    add_reference :users, :race, foreign_key: true
    add_reference :users, :classe_perso, foreign_key: true
  end
end
