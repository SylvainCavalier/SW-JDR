class AddStudyPointsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :study_points, :integer, default: 0
  end
end
