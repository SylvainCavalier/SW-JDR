class AddPatchToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :patch, :integer
  end
end
