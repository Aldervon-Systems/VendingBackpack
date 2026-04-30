class Route < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :employee
  has_many :stops, -> { order(position: :asc) }, dependent: :destroy

  before_validation :assign_employee_organization_if_blank

  def payload
    {
      "id" => id,
      "employeeId" => employee_id,
      "employeeName" => employee_name,
      "distanceMeters" => distance_meters.to_f,
      "durationSeconds" => duration_seconds.to_f,
      "stops" => stops.map(&:payload),
      "createdAt" => created_at&.iso8601,
      "updatedAt" => updated_at&.iso8601
    }
  end

  def self.empty_payload(employee)
    {
      "id" => nil,
      "employeeId" => employee.id,
      "employeeName" => employee.name,
      "distanceMeters" => 0.0,
      "durationSeconds" => 0.0,
      "stops" => [],
      "createdAt" => nil,
      "updatedAt" => nil
    }
  end

  private

  def assign_employee_organization_if_blank
    self.organization_id ||= employee&.organization_id
  end
end
