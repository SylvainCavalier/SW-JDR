class CreatePazaakGames < ActiveRecord::Migration[7.1]
  def change
    create_table :pazaak_games do |t|
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.references :guest, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.integer :current_turn_user_id
      t.integer :round_number, null: false, default: 1
      t.integer :wins_host, null: false, default: 0
      t.integer :wins_guest, null: false, default: 0
      t.text :host_state, null: false, default: "{}"
      t.text :guest_state, null: false, default: "{}"
      t.integer :last_drawn_card
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end
  end
end


