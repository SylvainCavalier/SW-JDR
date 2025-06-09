class AddScaleAndCapacityToShips < ActiveRecord::Migration[7.1]
  def change
    add_column :ships, :scale, :integer, default: 0, null: false
    add_column :ships, :capacity, :integer, default: 0, null: false
  end
end
