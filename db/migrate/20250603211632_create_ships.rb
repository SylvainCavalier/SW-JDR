class CreateShips < ActiveRecord::Migration[7.1]
  def change
    create_table :ships do |t|
      t.string :name
      t.integer :price
      t.string :brand
      t.string :model
      t.text :description
      t.string :size
      t.integer :max_passengers
      t.integer :min_crew
      t.integer :hp_max
      t.integer :hp_current
      t.integer :turret, default: 0 # enum: 0=blaster, 1=plasmique, 2=lourde
      t.integer :hyperdrive_rating
      t.boolean :backup_hyperdrive, default: false
      t.boolean :active, default: false
      t.integer :parent_ship_id, index: true
      t.references :group, foreign_key: true
      t.timestamps
    end
    add_foreign_key :ships, :ships, column: :parent_ship_id
  end
end
