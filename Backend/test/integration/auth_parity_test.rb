require "test_helper"

class AuthParityTest < ActionDispatch::IntegrationTest
  setup do
    Stop.delete_all
    Route.delete_all
    Machine.delete_all
    Employee.delete_all
    Item.delete_all
    MachineInventory.delete_all
    WarehouseMovement.delete_all
  end

  test "employee with matching sql employee can fetch own route" do
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
    assert_equal ["M-600"], json_response.fetch("stops").map { |row| row["id"] }
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
