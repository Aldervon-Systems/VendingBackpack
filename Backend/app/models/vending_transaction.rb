class VendingTransaction < ApplicationRecord
  STATUS_COMPLETED = "completed"
  STATUS_REFUNDED = "refunded"
  STATUSES = [STATUS_COMPLETED, STATUS_REFUNDED].freeze

  belongs_to :organization, optional: true
  belongs_to :item
  belongs_to :machine, foreign_key: :machine_id, primary_key: :id, optional: true

  before_validation :assign_related_organization_if_blank

  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :completed_at, presence: true

  def payload
    {
      "id" => id,
      "itemId" => item_id,
      "itemName" => item.name,
      "machineId" => machine_id,
      "slotNumber" => slot_number,
      "amount" => amount.to_f,
      "status" => status,
      "paymentMethod" => payment_method,
      "userId" => user_id,
      "completedAt" => completed_at&.iso8601,
      "refundedAt" => refunded_at&.iso8601,
      "createdAt" => created_at&.iso8601,
      "updatedAt" => updated_at&.iso8601
    }
  end

  private

  def assign_related_organization_if_blank
    self.organization_id ||= machine&.organization_id || item&.organization_id
  end
end
