class CreateInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_objects do |t|
      t.string :name
      t.string :category
      t.text :description
      t.integer :price
      t.string :rarity
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
