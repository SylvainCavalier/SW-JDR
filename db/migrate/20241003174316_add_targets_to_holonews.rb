class AddTargetsToHolonews < ActiveRecord::Migration[7.1]
  def change
    add_column :holonews, :target_user, :integer
    add_column :holonews, :target_group, :string
  end
end
