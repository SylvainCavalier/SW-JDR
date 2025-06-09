class ChangeSizeAndHyperdriveRatingInShips < ActiveRecord::Migration[7.1]
  def change
    change_column :ships, :size, :integer, using: 'size::integer'
    change_column :ships, :hyperdrive_rating, :float
  end
end
