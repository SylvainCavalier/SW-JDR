class CreateShipCombatPositions < ActiveRecord::Migration[7.1]
  def change
    create_table :ship_combat_positions do |t|
      t.references :space_combat_state, null: false, foreign_key: true
      t.references :participant_a, null: false, foreign_key: { to_table: :space_combat_participants }
      t.references :participant_b, null: false, foreign_key: { to_table: :space_combat_participants }
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :ship_combat_positions,
              [:space_combat_state_id, :participant_a_id, :participant_b_id],
              unique: true,
              name: "index_ship_combat_pos_unique_pair"
  end
end
