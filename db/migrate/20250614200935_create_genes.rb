class CreateGenes < ActiveRecord::Migration[7.1]
  def change
    create_table :genes do |t|
      t.string :property, null: false
      t.boolean :positive, default: true, null: false
      t.integer :category, null: false
      t.text :description
      t.jsonb :skill_bonuses, default: {}
      t.jsonb :stats_bonuses, default: {}
      t.jsonb :special_traits, default: []

      t.timestamps
    end
  end
end
