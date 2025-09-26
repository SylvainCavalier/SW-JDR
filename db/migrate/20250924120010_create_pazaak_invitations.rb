class CreatePazaakInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :pazaak_invitations do |t|
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :invitee, null: false, foreign_key: { to_table: :users }
      t.references :pazaak_game, foreign_key: true
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :pazaak_invitations, [:inviter_id, :invitee_id, :status]
  end
end


