class GoodsCrate < ApplicationRecord
  belongs_to :user

  validates :content, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :origin_planet, presence: true
  validates :price_per_crate, presence: true, numericality: { greater_than_or_equal_to: 0 }
end

