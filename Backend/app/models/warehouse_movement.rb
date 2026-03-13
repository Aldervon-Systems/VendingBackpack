class WarehouseMovement < ApplicationRecord
  belongs_to :item

  validates :movement_type, presence: true
  validates :quantity_delta, numericality: { other_than: 0 }
  validates :balance_after, numericality: { greater_than_or_equal_to: 0 }
end
