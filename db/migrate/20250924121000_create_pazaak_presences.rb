class CreatePazaakPresences < ActiveRecord::Migration[7.1]
  def change
    create_table :pazaak_presences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.datetime :last_seen_at, null: false
      t.timestamps
    end
  end
end


