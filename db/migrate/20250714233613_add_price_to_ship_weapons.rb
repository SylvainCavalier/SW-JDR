class AddPriceToShipWeapons < ActiveRecord::Migration[7.1]
  def change
    add_column :ship_weapons, :price, :integer, default: 0, null: false
  end
end
