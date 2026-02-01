class AddAllyToEnemies < ActiveRecord::Migration[7.1]
  def change
    add_column :enemies, :ally, :boolean, default: false
  end
end
