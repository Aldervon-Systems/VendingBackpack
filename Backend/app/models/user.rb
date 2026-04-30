class User < ApplicationRecord
  self.primary_key = :id

  ROLES = %w[platform_admin manager employee].freeze

  has_secure_password

  belongs_to :organization, optional: true
  has_many :managed_organizations, class_name: "Organization", foreign_key: :manager_id, dependent: :nullify

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: ROLES }

  def auth_payload
    {
      "id" => id,
      "name" => name,
      "email" => email,
      "role" => role,
      "organization_id" => organization_id,
      "organization_name" => organization&.name
    }
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
