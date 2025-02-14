class AddReadToHolonews < ActiveRecord::Migration[7.1]
  def change
    add_column :holonews, :read, :boolean, default: false
  end
end