class CreateCombatStates < ActiveRecord::Migration[7.1]
  def change
    create_table :combat_states do |t|
      t.integer :turn

      t.timestamps
    end
  end
end
