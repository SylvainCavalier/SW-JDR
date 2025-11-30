class AddFullStatsToApprentices < ActiveRecord::Migration[7.1]
  def change
    # Ajouter user_id à la table apprentices (le maître Jedi)
    add_reference :apprentices, :user, null: false, foreign_key: true

    # Ajouter dark_side_points comme pour les users
    add_column :apprentices, :dark_side_points, :integer, default: 0

    # Créer la table apprentice_caracs pour les caractéristiques de l'apprenti
    create_table :apprentice_caracs do |t|
      t.references :apprentice, null: false, foreign_key: true
      t.references :carac, null: false, foreign_key: true
      t.integer :mastery, default: 0, null: false
      t.integer :bonus, default: 0, null: false

      t.timestamps
    end

    add_index :apprentice_caracs, [:apprentice_id, :carac_id], unique: true

    # Créer la table apprentice_skills pour les compétences de l'apprenti
    create_table :apprentice_skills do |t|
      t.references :apprentice, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :mastery, default: 0, null: false
      t.integer :bonus, default: 0, null: false

      t.timestamps
    end

    add_index :apprentice_skills, [:apprentice_id, :skill_id], unique: true
  end
end

