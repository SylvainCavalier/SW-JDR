class AddFirstPlayerIdToPazaakGames < ActiveRecord::Migration[7.1]
  def change
    add_column :pazaak_games, :first_player_id, :integer
    add_index :pazaak_games, :first_player_id
  end
end


