class CreateUserCaracs < ActiveRecord::Migration[7.1]
  def change
    create_table :user_caracs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :carac, null: false, foreign_key: true
      t.integer :mastery
      t.integer :bonus

      t.timestamps
    end
  end
end
