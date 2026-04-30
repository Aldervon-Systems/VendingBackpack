class WarehouseMovement < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :item

  before_validation :assign_related_organization_if_blank

  validates :movement_type, presence: true
  validates :quantity_delta, numericality: { other_than: 0 }
  validates :balance_after, numericality: { greater_than_or_equal_to: 0 }

  private

  def assign_related_organization_if_blank
    self.organization_id ||= item&.organization_id
  end
end
