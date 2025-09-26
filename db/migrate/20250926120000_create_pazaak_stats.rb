class CreatePazaakStats < ActiveRecord::Migration[7.1]
  def change
    create_table :pazaak_stats do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :games_played, default: 0, null: false
      t.integer :games_won, default: 0, null: false
      t.integer :games_lost, default: 0, null: false
      t.integer :rounds_won, default: 0, null: false
      t.integer :rounds_lost, default: 0, null: false
      t.integer :rounds_tied, default: 0, null: false
      t.integer :games_abandoned, default: 0, null: false
      t.integer :best_win_streak, default: 0, null: false
      t.integer :worst_lose_streak, default: 0, null: false
      t.integer :current_win_streak, default: 0, null: false
      t.integer :current_lose_streak, default: 0, null: false
      t.integer :credits_won, default: 0, null: false
      t.integer :credits_lost, default: 0, null: false
      t.integer :stake_max, default: 0, null: false
      t.integer :stake_min, default: 0, null: false
      t.integer :stake_sum, default: 0, null: false
      t.integer :stake_count, default: 0, null: false
      t.integer :playmate_user_id
      t.integer :nemesis_user_id
      t.integer :victim_user_id
      t.jsonb    :opponent_counters, default: {}
      t.timestamps
    end
  end
end


