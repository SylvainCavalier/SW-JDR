class AddActiveInjectionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :active_injection, :integer, null: true
  end
end
