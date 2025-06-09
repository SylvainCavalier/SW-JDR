class AddUsedCapacityToShips < ActiveRecord::Migration[7.1]
  def change
    add_column :ships, :used_capacity, :integer, default: 0, null: false
  end
end 