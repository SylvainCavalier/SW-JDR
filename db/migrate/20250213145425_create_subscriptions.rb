class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.text :endpoint
      t.text :p256dh
      t.text :auth

      t.timestamps
    end
  end
end
