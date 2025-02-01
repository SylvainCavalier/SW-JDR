class AddShieldToPets < ActiveRecord::Migration[7.1]
  def change
    add_column :pets, :shield_current, :integer, default: 0
    add_column :pets, :shield_max, :integer, default: 0
  end
end
