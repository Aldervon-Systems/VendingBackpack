class OrganizationWhitelistEntry < ApplicationRecord
  belongs_to :organization

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { scope: :organization_id }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
