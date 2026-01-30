class CreateSpaceCombatStates < ActiveRecord::Migration[7.1]
  def change
    create_table :space_combat_states do |t|
      t.integer :turn, default: 1
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
