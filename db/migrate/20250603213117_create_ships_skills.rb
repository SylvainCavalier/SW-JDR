class CreateShipsSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :ships_skills do |t|
      t.references :ship, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :mastery
      t.integer :bonus

      t.timestamps
    end
  end
end
