class CreateSpaceCombatActions < ActiveRecord::Migration[7.1]
  def change
    create_table :space_combat_actions do |t|
      t.references :space_combat_state, null: false, foreign_key: true
      t.references :actor_participant, null: false, foreign_key: { to_table: :space_combat_participants }
      t.references :actor_crew_user, foreign_key: { to_table: :users }
      t.references :target_participant, foreign_key: { to_table: :space_combat_participants }
      t.string :action_type, null: false
      t.text :value
      t.timestamps
    end
  end
end
