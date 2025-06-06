class CreateShipWeapons < ActiveRecord::Migration[7.1]
  def change
    create_table :ship_weapons do |t|
      t.string :name, null: false
      t.string :weapon_type, null: false
      t.integer :quantity_max
      t.integer :quantity_current
      t.integer :damage_mastery, default: 0
      t.integer :damage_bonus, default: 0
      t.integer :aim_mastery, default: 0
      t.integer :aim_bonus, default: 0
      t.string :special
      t.text :description
      t.references :ship, null: false, foreign_key: true

      t.timestamps
    end
  end
end
