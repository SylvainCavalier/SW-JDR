class CreateSpaceCombatParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :space_combat_participants do |t|
      t.references :space_combat_state, null: false, foreign_key: true
      t.string :participant_type, null: false
      t.bigint :participant_id, null: false
      t.integer :side, default: 0
      t.integer :initiative_roll
      t.integer :action_order
      t.boolean :offensive_action_used, default: false
      t.boolean :movement_action_used, default: false
      t.integer :defense_malus, default: 0
      t.boolean :has_played, default: false
      t.timestamps
    end

    add_index :space_combat_participants, [:participant_type, :participant_id],
              name: "index_scp_on_participant"
    add_index :space_combat_participants, [:space_combat_state_id, :action_order],
              name: "index_scp_on_state_and_order"
  end
end
