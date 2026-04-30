class Shipment < ApplicationRecord
  belongs_to :organization, optional: true

  before_validation :assign_single_organization_if_blank

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :scheduled_for, presence: true
  validates :status, presence: true

  def payload
    {
      "id" => id,
      "description" => description,
      "amount" => amount,
      "scheduledFor" => scheduled_for.iso8601,
      "status" => status,
      "createdAt" => created_at&.iso8601,
      "updatedAt" => updated_at&.iso8601
    }
  end

  private

  def assign_single_organization_if_blank
    return if organization_id.present?

    self.organization = Organization.first if Organization.count == 1
  end
end
