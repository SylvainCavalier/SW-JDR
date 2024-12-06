class AddPetIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :pet, foreign_key: true, null: true
  end
end
