class CreateEmbryoSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :embryo_skills do |t|
      t.references :embryo, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :mastery, default: 0, null: false
      t.integer :bonus, default: 0, null: false

      t.timestamps
    end

    add_index :embryo_skills, [:embryo_id, :skill_id], unique: true
  end
end

