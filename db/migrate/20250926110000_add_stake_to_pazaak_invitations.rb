class AddStakeToPazaakInvitations < ActiveRecord::Migration[7.1]
  def change
    add_column :pazaak_invitations, :stake, :integer, default: 0, null: false
  end
end


