class AddAstromechDroidsToShips < ActiveRecord::Migration[7.1]
  def change
    add_column :ships, :astromech_droids, :integer, default: 0, null: false
  end
end
