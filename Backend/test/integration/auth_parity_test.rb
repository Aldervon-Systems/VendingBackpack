require "test_helper"

class AuthParityTest < ActionDispatch::IntegrationTest
  setup do
    VendingTransaction.delete_all
    Stop.delete_all
    Route.delete_all
    Machine.delete_all
    Employee.delete_all
    Item.delete_all
    MachineInventory.delete_all
    WarehouseMovement.delete_all
  end

  test "token authenticates a seeded sql-backed manager account" do
    create_test_user(
      "id" => "renee_goodman",
      "name" => "Renee Goodman",
      "email" => "renee@aldervon.com",
      "password" => "password123",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    )

    post "/api/token",
         params: { email: "renee@aldervon.com", password: "password123" }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :success
    assert_equal "renee@aldervon.com", json_response.dig("user", "email")
    assert_equal "manager", json_response.dig("user", "role")
    assert json_response["access_token"].present?
  end

  test "signup enforces sql-backed organization whitelist" do
    organization = create_test_organization(id: "org_aldervon")
    organization.organization_whitelist_entries.create!(email: "allowed@aldervon.com")

    post "/api/signup",
         params: {
           name: "Allowed Employee",
           email: "blocked@aldervon.com",
           password: "password123",
           role: "employee",
           organization_id: organization.id
         }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :forbidden
    assert_equal "Email not authorized for this organization", json_response.fetch("detail")
  end

  test "signup creates a sql-backed user and employee record when whitelisted" do
    organization = create_test_organization(id: "org_aldervon")
    organization.organization_whitelist_entries.create!(email: "allowed@aldervon.com")

    post "/api/signup",
         params: {
           name: "Allowed Employee",
           email: "allowed@aldervon.com",
           password: "password123",
           role: "employee",
           organization_id: organization.id
         }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :created
    user_id = json_response.dig("user", "id")
    assert User.exists?(id: user_id)
    assert Employee.exists?(id: user_id)
    assert_equal "employee", json_response.dig("user", "role")
    assert_equal organization.id, Employee.find(user_id).organization_id
  end

  test "signup ignores manager role escalation" do
    organization = create_test_organization(id: "org_aldervon")
    organization.organization_whitelist_entries.create!(email: "allowed@aldervon.com")

    post "/api/signup",
         params: {
           name: "Escalation Attempt",
           email: "allowed@aldervon.com",
           password: "password123",
           role: "manager",
           organization_id: organization.id
         }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :created
    assert_equal "employee", json_response.dig("user", "role")
    assert_equal "employee", User.find(json_response.dig("user", "id")).role
  end

  test "organization provisioning persists org and whitelist in sql" do
    ensure_platform_admin!
    create_test_user(
      "id" => "provision_mgr",
      "name" => "Provision Manager",
      "email" => "provision.manager@example.com",
      "password" => "password123",
      "role" => "manager"
    )

    post "/api/organizations/create",
         params: {
           name: "Northwind Ops",
           manager_email: "provision.manager@example.com",
           admin_password: "admin-pass-123",
           whitelist: ["ops@northwind.test", "warehouse@northwind.test"]
         }.to_json,
         headers: platform_admin_headers

    assert_response :success

    organization = Organization.find(json_response.fetch("organization_id"))
    assert_equal "Northwind Ops", organization.name
    assert organization.authenticate_admin_password("admin-pass-123")
    assert_equal ["ops@northwind.test", "warehouse@northwind.test"], organization.organization_whitelist_entries.order(:email).pluck(:email)
    assert_equal organization.id, User.find("provision_mgr").organization_id
    assert_nil json_response["totp_seed"]
    assert_match(/\Aotpauth:\/\//, json_response.fetch("totp_uri"))
  end

  test "tenant manager cannot provision organizations" do
    ensure_default_manager!

    post "/api/organizations/create",
         params: {
           name: "Blocked Ops",
           admin_password: "admin-pass-123",
           whitelist: []
         }.to_json,
         headers: manager_headers

    assert_response :forbidden
  end

  test "admin verification reads sql-backed admin password and totp seed" do
    organization = create_test_organization(id: "org_aldervon", admin_password: "admin")
    valid_code = ROTP::TOTP.new(organization.totp_seed).now

    post "/api/organizations/verify_admin",
         params: {
           organization_id: organization.id,
           admin_password: "admin",
           totp_code: valid_code
         }.to_json,
         headers: manager_headers

    assert_response :success
    assert_equal true, json_response.fetch("verified")
  end

  test "admin verification failure is generic" do
    organization = create_test_organization(id: "org_aldervon", admin_password: "admin")

    post "/api/organizations/verify_admin",
         params: {
           organization_id: organization.id,
           admin_password: "wrong",
           totp_code: "000000"
         }.to_json,
         headers: manager_headers

    assert_response :unauthorized
    assert_equal "Invalid verification code or credentials", json_response.fetch("detail")
  end

  test "whitelist update writes sql-backed whitelist rows" do
    create_test_user(
      "id" => "user_admin",
      "name" => "Admin Manager",
      "email" => "admin@vbp.com",
      "password" => "password123",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    )

    post "/api/organizations/org_aldervon/whitelist",
         params: { emails: ["alpha@example.com", "beta@example.com"] }.to_json,
         headers: manager_headers

    assert_response :success
    assert_equal ["alpha@example.com", "beta@example.com"], Organization.find("org_aldervon").organization_whitelist_entries.order(:email).pluck(:email)
  end

  test "me resolves bearer tokens against sql-backed users" do
    create_test_user(
      "id" => "user_admin",
      "name" => "Admin Manager",
      "email" => "admin@vbp.com",
      "password" => "password123",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    )

    get "/api/me", headers: manager_headers

    assert_response :success
    assert_equal "user_admin", json_response.dig("user", "id")
    assert_equal "admin@vbp.com", json_response.dig("user", "email")
  end

  test "employee with matching sql employee can fetch own route" do
    create_test_organization(id: "org_aldervon")
    employee = Employee.create!(id: "emp_auth", name: "Auth Employee", color: 0xFF112233, is_active: true)
    machine = Machine.create!(id: "M-600", name: "Machine 600", lat: 42.0, lng: -71.0)
    route = Route.create!(employee: employee, employee_name: employee.name, distance_meters: 0, duration_seconds: 0)
    route.stops.create!(machine: machine, position: 0)

    with_stubbed_user(
      "id" => employee.id,
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/employees/#{employee.id}/routes", headers: employee_headers(user_id: employee.id)
    end

    assert_response :success
    assert_equal ["M-600"], json_response.fetch("stops").map { |row| row["machineId"] }
  end

  test "employee route read fails closed when sql employee parity is missing" do
    with_stubbed_user(
      "id" => "missing_emp",
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/employees/missing_emp/routes", headers: employee_headers(user_id: "missing_emp")
    end

    assert_response :forbidden
    assert_equal "Forbidden", json_response.fetch("detail")
  end
end
