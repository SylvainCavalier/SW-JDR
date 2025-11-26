class AddDiscoveredDrinksToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :discovered_drinks, :jsonb, default: []
  end
end
