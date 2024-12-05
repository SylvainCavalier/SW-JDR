class CreateUserSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :user_skills do |t|
      t.references :user, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :mastery, default: 0, null: false
      t.integer :bonus, default: 0, null: false

      t.timestamps
    end
  end
end
