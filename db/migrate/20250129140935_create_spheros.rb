class CreateSpheros < ActiveRecord::Migration[7.1]
  def change
    create_table :spheros do |t|
      t.string :name, default: "Sphéro-Droïde"
      t.string :category, null: false
      t.integer :quality, null: false
      t.integer :medipacks, default: 0
      t.integer :hp_current, default: 20
      t.integer :hp_max, default: 20
      t.integer :shield_current, default: 0
      t.integer :shield_max, default: 0
      t.references :user, foreign_key: true
      
      t.timestamps
    end

    create_table :sphero_skills do |t|
      t.references :sphero, foreign_key: true
      t.references :skill, foreign_key: true
      t.integer :mastery, null: false
      t.integer :bonus, default: 0
      
      t.timestamps
    end
  end
end
