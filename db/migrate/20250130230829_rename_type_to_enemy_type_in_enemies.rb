class RenameTypeToEnemyTypeInEnemies < ActiveRecord::Migration[7.1]
  def change
    rename_column :enemies, :type, :enemy_type
  end
end
