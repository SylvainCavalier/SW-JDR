class AddActiveParticipantToCombatStates < ActiveRecord::Migration[7.1]
  def change
    add_column :combat_states, :active_participant_type, :string
    add_column :combat_states, :active_participant_id, :bigint
  end
end
