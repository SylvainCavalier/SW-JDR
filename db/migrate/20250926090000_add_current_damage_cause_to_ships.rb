class AddCurrentDamageCauseToShips < ActiveRecord::Migration[7.0]
  def change
    add_column :ships, :current_damage_cause, :string
  end
end


