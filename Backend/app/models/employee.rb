class Employee < ApplicationRecord
  self.primary_key = :id
  belongs_to :organization, optional: true
  has_one :route, dependent: :destroy

  before_validation :assign_single_organization_if_blank

  def payload
    {
      "id" => id,
      "name" => name,
      "color" => color,
      "department" => department,
      "location" => location,
      "floor" => floor,
      "building" => building,
      "isActive" => is_active,
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
