class AddDefaultStatusToPets < ActiveRecord::Migration[7.1]
  def change
    change_column_default :pets, :status_id, from: nil, to: Status.find_by(name: "En forme").id
  end
end
