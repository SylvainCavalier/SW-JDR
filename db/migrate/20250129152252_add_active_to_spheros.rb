class AddActiveToSpheros < ActiveRecord::Migration[7.1]
  def change
    add_column :spheros, :active, :boolean, default: false
  end
end
