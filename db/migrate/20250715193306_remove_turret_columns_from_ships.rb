class RemoveTurretColumnsFromShips < ActiveRecord::Migration[7.1]
  def change
    remove_column :ships, :turret, :integer
    remove_column :ships, :tourelles, :integer
  end
end
