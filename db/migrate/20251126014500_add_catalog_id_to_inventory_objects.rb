class AddCatalogIdToInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :inventory_objects, :catalog_id, :string
    add_index :inventory_objects, :catalog_id
  end
end
