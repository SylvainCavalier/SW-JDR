class CreateEnemyShips < ActiveRecord::Migration[7.1]
  def change
    create_table :enemy_ships do |t|
      t.string :name, null: false
      t.integer :hp_current, default: 0
      t.integer :hp_max, default: 0
      t.integer :shield_current, default: 0
      t.integer :shield_max, default: 0
      t.integer :speed_mastery, default: 0
      t.integer :speed_bonus, default: 0
      t.integer :piloting_mastery, default: 0
      t.integer :piloting_bonus, default: 0
      t.integer :scale, default: 0
      t.boolean :shields_disabled, default: false
      t.boolean :controls_ionized, default: false
      t.boolean :weapon_damaged, default: false
      t.boolean :thrusters_damaged, default: false
      t.boolean :hyperdrive_broken, default: false
      t.boolean :depressurized, default: false
      t.boolean :ship_destroyed, default: false
      t.timestamps
    end
  end
end
