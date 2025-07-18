class CreateCrewMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :crew_members do |t|
      t.references :ship, null: false, foreign_key: true
      t.string :assignable_type
      t.integer :assignable_id
      t.string :position

      t.timestamps
    end
  end
end
