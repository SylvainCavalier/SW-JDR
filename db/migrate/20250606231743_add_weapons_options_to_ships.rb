class AddWeaponsOptionsToShips < ActiveRecord::Migration[7.1]
  def change
    add_column :ships, :tourelles, :integer
    add_column :ships, :torpilles, :boolean
    add_column :ships, :missiles, :boolean
  end
end
