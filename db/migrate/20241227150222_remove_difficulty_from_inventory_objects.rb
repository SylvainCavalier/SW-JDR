class RemoveDifficultyFromInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    remove_column :inventory_objects, :difficulty, :integer
  end
end
