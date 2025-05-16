class AddSenderAliasToHolonews < ActiveRecord::Migration[7.1]
  def change
    add_column :holonews, :sender_alias, :string
  end
end
