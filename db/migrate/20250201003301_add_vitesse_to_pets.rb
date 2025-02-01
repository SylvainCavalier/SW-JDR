class AddVitesseToPets < ActiveRecord::Migration[7.1]
  def change
    add_column :pets, :vitesse, :integer
  end
end
