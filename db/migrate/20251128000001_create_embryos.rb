class CreateEmbryos < ActiveRecord::Migration[7.1]
  def change
    create_table :embryos do |t|
      t.string :name, null: false
      t.string :creature_type, null: false
      t.string :race
      t.string :gender
      t.string :status, default: "stocké"
      t.string :weapon
      t.integer :damage_1, default: 0
      t.integer :damage_bonus_1, default: 0
      t.jsonb :special_traits, default: []
      t.boolean :force, default: false
      t.integer :size
      t.integer :weight
      t.integer :hp_max, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

