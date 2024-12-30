class AddDifficultyToInventoryObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :inventory_objects, :difficulty, :integer, null: true
  end
end
