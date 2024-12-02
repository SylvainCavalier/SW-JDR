class RemoveUserIdFromInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    remove_column :inventory_objects, :user_id, :integer
  end
end
