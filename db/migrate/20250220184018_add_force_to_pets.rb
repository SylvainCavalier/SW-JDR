class AddForceToPets < ActiveRecord::Migration[7.1]
  def change
    add_column :pets, :force, :boolean
  end
end
