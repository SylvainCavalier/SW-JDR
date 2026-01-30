class CreateEnemyShipWeapons < ActiveRecord::Migration[7.1]
  def change
    create_table :enemy_ship_weapons do |t|
      t.references :enemy_ship, null: false, foreign_key: true
      t.string :weapon_type, null: false
      t.string :name, null: false
      t.integer :damage_mastery, default: 0
      t.integer :damage_bonus, default: 0
      t.integer :aim_mastery, default: 0
      t.integer :aim_bonus, default: 0
      t.integer :quantity_current
      t.integer :quantity_max
      t.timestamps
    end
  end
end
