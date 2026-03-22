require "test_helper"

class RoutesConsistencyTest < ActionDispatch::IntegrationTest
  setup do
    Stop.delete_all
    Route.delete_all
    Machine.delete_all
    Employee.delete_all
  end

  test "routes and employee listings come from persisted records" do
    employee = Employee.create!(id: "emp_1", name: "Amanda Jones", color: 0xFF123456, is_active: true)
    machine = Machine.create!(id: "M-200", name: "Lobby Machine", lat: 42.0, lng: -71.0)
    route = Route.create!(employee: employee, employee_name: employee.name, distance_meters: 10, duration_seconds: 20)
    route.stops.create!(machine: machine, position: 0)

    get "/api/employees", headers: manager_headers
    assert_response :success
    assert_equal ["emp_1"], json_response.map { |row| row["id"] }

    get "/api/routes", headers: manager_headers
    assert_response :success
    assert_equal ["M-200"], json_response.fetch("locations").map { |row| row["id"] }

    get "/api/employees/routes", headers: manager_headers
    assert_response :success
    assert_equal ["emp_1"], json_response.map { |row| row["employee_id"] }

    get "/api/employees/#{employee.id}/routes", headers: manager_headers
    assert_response :success
    assert_equal ["M-200"], json_response.fetch("stops").map { |row| row["id"] }
  end
end
