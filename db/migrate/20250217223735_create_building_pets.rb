class CreateBuildingPets < ActiveRecord::Migration[7.1]
  def change
    create_table :building_pets do |t|
      t.references :building, null: false, foreign_key: true
      t.references :pet, null: false, foreign_key: true

      t.timestamps
    end
  end
end
