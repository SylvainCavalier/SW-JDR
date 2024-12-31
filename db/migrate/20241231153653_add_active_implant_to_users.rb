class AddActiveImplantToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :active_implant, :integer
  end
end
