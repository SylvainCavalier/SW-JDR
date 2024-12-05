class AddHomeopathieToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :homeopathie, :boolean, default: false
  end
end
