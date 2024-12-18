class AddPetActionPointsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :pet_action_points, :integer, default: 10
  end
end
