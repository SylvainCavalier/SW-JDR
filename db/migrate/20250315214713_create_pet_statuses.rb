class CreatePetStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :pet_statuses do |t|
      t.references :pet, null: false, foreign_key: true
      t.references :status, null: false, foreign_key: true

      t.timestamps
    end
  end
end
