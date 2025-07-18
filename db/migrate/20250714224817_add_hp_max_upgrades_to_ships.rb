class AddHpMaxUpgradesToShips < ActiveRecord::Migration[7.1]
  def change
    add_column :ships, :hp_max_upgrades, :integer, default: 0, null: false
  end
end
