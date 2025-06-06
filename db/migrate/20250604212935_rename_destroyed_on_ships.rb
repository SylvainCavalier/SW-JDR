class RenameDestroyedOnShips < ActiveRecord::Migration[7.1]
  def change
    rename_column :ships, :destroyed, :ship_destroyed
  end
end
