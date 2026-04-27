class AddBrokenToSpheros < ActiveRecord::Migration[7.1]
  def change
    add_column :spheros, :broken, :boolean, default: false, null: false
  end
end
