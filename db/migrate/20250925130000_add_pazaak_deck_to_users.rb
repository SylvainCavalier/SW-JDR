class AddPazaakDeckToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :pazaak_deck, :jsonb, default: []
  end
end


