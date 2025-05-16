class AddJunkieToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :junkie, :boolean, default: false
  end
end
