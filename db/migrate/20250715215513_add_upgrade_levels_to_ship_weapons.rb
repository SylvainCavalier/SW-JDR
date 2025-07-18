class AddUpgradeLevelsToShipWeapons < ActiveRecord::Migration[7.1]
  def change
    add_column :ship_weapons, :damage_upgrade_level, :integer, default: 0, null: false
    add_column :ship_weapons, :aim_upgrade_level, :integer, default: 0, null: false
  end
end
