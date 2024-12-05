class AddEchaniShieldToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :echani_shield_state, :boolean
    add_column :users, :echani_shield_current, :integer
    add_column :users, :echani_shield_max, :integer
  end
end
