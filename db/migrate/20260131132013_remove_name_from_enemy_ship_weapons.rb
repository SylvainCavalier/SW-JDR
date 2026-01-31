class RemoveNameFromEnemyShipWeapons < ActiveRecord::Migration[7.1]
  def change
    remove_column :enemy_ship_weapons, :name, :string
  end
end
