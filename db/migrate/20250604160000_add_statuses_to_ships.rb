class AddStatusesToShips < ActiveRecord::Migration[7.1]
  def change
    add_column :ships, :shields_disabled, :boolean, default: false
    add_column :ships, :controls_ionized, :boolean, default: false
    add_column :ships, :weapon_damaged, :boolean, default: false
    add_column :ships, :thrusters_damaged, :boolean, default: false
    add_column :ships, :hyperdrive_broken, :boolean, default: false
    add_column :ships, :depressurized, :boolean, default: false
    add_column :ships, :destroyed, :boolean, default: false
  end
end 