class CreatePetSkills < ActiveRecord::Migration[7.0]
  def change
    create_table :pet_skills do |t|
      t.references :pet, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :mastery, default: 0, null: false
      t.integer :bonus, default: 0, null: false

      t.timestamps
    end
  end
end
