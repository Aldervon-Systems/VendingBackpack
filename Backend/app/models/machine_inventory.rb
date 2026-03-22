class MachineInventory < ApplicationRecord
  belongs_to :machine, foreign_key: :machine_id, primary_key: :id
  belongs_to :item

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
end
