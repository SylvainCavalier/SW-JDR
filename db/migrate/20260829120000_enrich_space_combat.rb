class EnrichSpaceCombat < ActiveRecord::Migration[7.1]
  def change
    change_table :space_combat_participants, bulk: true do |t|
      t.integer :shields_down_until_turn
      t.integer :pending_repair, default: 0, null: false
      t.boolean :repair_used, default: false, null: false
      t.integer :thruster_hits, default: 0, null: false
      t.integer :depressurized_since_turn
      t.integer :astrogation_turns, default: 0, null: false
      t.boolean :astrogation_started, default: false, null: false
      t.boolean :hyperspace_ready, default: false, null: false
      t.boolean :has_fled, default: false, null: false
      t.boolean :stealth, default: false, null: false
      t.boolean :detected, default: false, null: false
      t.integer :captain_bonus, default: 0, null: false
      t.boolean :command_used, default: false, null: false
    end

    change_table :ship_combat_positions, bulk: true do |t|
      t.bigint :blind_spot_for_id
      t.boolean :engaged, default: false, null: false
    end

    add_column :enemy_ships, :interception_level, :integer, default: 0, null: false
  end
end
