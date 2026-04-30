class Machine < ApplicationRecord
  self.primary_key = :id

  belongs_to :organization, optional: true
  has_many :machine_inventories, foreign_key: :machine_id, primary_key: :id, dependent: :destroy
  has_many :stops, foreign_key: :machine_id, primary_key: :id, dependent: :nullify
  has_many :vending_transactions, foreign_key: :machine_id, primary_key: :id, dependent: :nullify

  before_validation :assign_single_organization_if_blank

  def payload
    {
      "id" => id,
      "name" => name,
      "vin" => vin,
      "organizationId" => organization_id,
      "status" => status,
      "battery" => battery,
      "lat" => lat,
      "lng" => lng,
      "location" => location,
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
