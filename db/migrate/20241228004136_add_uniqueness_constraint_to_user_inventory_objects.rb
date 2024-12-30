class AddUniquenessConstraintToUserInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    add_index :user_inventory_objects, [:user_id, :inventory_object_id], unique: true
  end
end
