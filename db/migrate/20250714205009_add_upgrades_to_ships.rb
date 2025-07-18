class AddUpgradesToShips < ActiveRecord::Migration[7.1]
  def change
    add_column :ships, :thruster_level, :integer, default: 0, null: false
    add_column :ships, :hull_level, :integer, default: 0, null: false
    add_column :ships, :circuits_level, :integer, default: 0, null: false
    add_column :ships, :shield_system_level, :integer, default: 0, null: false
  end
end
