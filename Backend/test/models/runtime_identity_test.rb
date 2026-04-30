require "test_helper"

class RuntimeIdentityTest < ActiveSupport::TestCase
  test "user normalizes email and authenticates with bcrypt" do
    organization = create_test_organization(id: "org_aldervon")
    user = User.create!(
      id: "user_admin",
      name: "Admin Manager",
      email: "ADMIN@VBP.COM ",
      password: "password123",
      password_confirmation: "password123",
      role: "manager",
      organization: organization
    )

    assert_equal "admin@vbp.com", user.email
    assert user.authenticate("password123")
    assert_equal "Aldervon Systems", user.auth_payload.fetch("organization_name")
  end

  test "organization whitelist normalizes email and enforces uniqueness per org" do
    organization = create_test_organization(id: "org_aldervon")
    OrganizationWhitelistEntry.create!(organization: organization, email: "Employee@Aldervon.com ")

    duplicate = OrganizationWhitelistEntry.new(organization: organization, email: "employee@aldervon.com")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
    assert_equal ["employee@aldervon.com"], organization.organization_whitelist_entries.pluck(:email)
  end
end
