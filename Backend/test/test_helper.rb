ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module TestIdentityHelpers
  def create_test_organization(id:, name: "Aldervon Systems", manager_id: nil, admin_password: "admin", totp_seed: "JBSWY3DPEHPK3PXP")
    organization = Organization.find_or_initialize_by(id: id)
    organization.name = name
    organization.manager_id = manager_id
    organization.totp_seed = totp_seed
    organization.admin_password = admin_password
    organization.admin_password_confirmation = admin_password
    organization.save!
    organization
  end

  def create_test_user(user)
    organization_id = user["organization_id"].presence
    create_test_organization(id: organization_id) if organization_id

    record = User.find_or_initialize_by(id: user.fetch("id").to_s)
    record.name = user["name"].presence || user.fetch("id").to_s.humanize
    record.email = user.fetch("email", "#{user.fetch('id')}@example.com").to_s.downcase
    record.role = user.fetch("role").to_s
    record.organization_id = organization_id

    password = user["password"].presence || "password123"
    record.password = password
    record.password_confirmation = password
    record.save!

    record.organization&.update!(manager: record) if record.role == "manager" && record.organization&.manager_id.nil?
    record
  end
end

class ActiveSupport::TestCase
  include TestIdentityHelpers

  parallelize(workers: 1)

  setup do
    next unless ActiveRecord::Base.connected?

    [
      VendingTransaction,
      WarehouseMovement,
      MachineInventory,
      Shipment,
      Stop,
      Route,
      Machine,
      Item,
      Employee,
      OrganizationWhitelistEntry,
      User,
      Organization
    ].each do |model|
      next unless model.table_exists?

      model.delete_all
    end

    create_test_organization(id: "org_aldervon") if Organization.table_exists?
  end
end

class ActionDispatch::IntegrationTest
  include TestIdentityHelpers

  private

  def with_stubbed_user(user)
    create_test_user(user)
    yield
  end

  def manager_headers
    ensure_default_manager!
    auth_headers(user_id: "user_admin", role: "manager", organization_id: "org_aldervon")
  end

  def platform_admin_headers
    ensure_platform_admin!
    auth_headers(user_id: "platform_admin", role: "platform_admin", organization_id: nil)
  end

  def employee_headers(user_id:, organization_id: "org_aldervon")
    auth_headers(user_id: user_id, role: "employee", organization_id: organization_id)
  end

  def auth_headers(user_id:, role:, organization_id:)
    token = Rails.application.message_verifier(:access_token).generate(
      {
        "sub" => user_id,
        "role" => role,
        "organization_id" => organization_id,
        "exp" => Time.now.to_i + 3600
      }
    )

    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  def json_response
    JSON.parse(response.body)
  end

  def ensure_default_manager!
    create_test_user(
      "id" => "user_admin",
      "name" => "Admin Manager",
      "email" => "admin@vbp.com",
      "password" => "password123",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    )
  end

  def ensure_platform_admin!
    create_test_user(
      "id" => "platform_admin",
      "name" => "Platform Admin",
      "email" => "platform@aldervon.com",
      "password" => "password123",
      "role" => "platform_admin"
    )
  end

end
