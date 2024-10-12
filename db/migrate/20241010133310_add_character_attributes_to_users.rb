class AddCharacterAttributesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :race, :string
    add_column :users, :class_name, :string
    add_column :users, :hp_max, :integer
    add_column :users, :hp_current, :integer
    add_column :users, :shield_state, :boolean
    add_column :users, :shield_max, :integer
    add_column :users, :shield_current, :integer
  end
end
