class ReplaceShieldHpWithSkillsOnEnemyShips < ActiveRecord::Migration[7.1]
  def change
    add_column :enemy_ships, :hull_mastery, :integer, default: 1, null: false
    add_column :enemy_ships, :hull_bonus, :integer, default: 0, null: false
    add_column :enemy_ships, :shield_mastery, :integer, default: 0, null: false
    add_column :enemy_ships, :shield_bonus, :integer, default: 0, null: false
    remove_column :enemy_ships, :shield_current, :integer
    remove_column :enemy_ships, :shield_max, :integer
  end
end
