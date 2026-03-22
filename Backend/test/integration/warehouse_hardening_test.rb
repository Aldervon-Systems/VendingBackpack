require "test_helper"

class WarehouseHardeningTest < ActionDispatch::IntegrationTest
  setup do
    WarehouseMovement.delete_all
    MachineInventory.delete_all
    Shipment.delete_all
    Item.delete_all
    Stop.delete_all
    Route.delete_all
    Machine.delete_all
    Employee.delete_all
  end

  test "warehouse index returns all canonical items including zero balances" do
    Item.create!(sku: "chips", name: "Chips", warehouse_quantity: 0, barcode: "111")
    Item.create!(sku: "water", name: "Water", warehouse_quantity: 5, barcode: "222")

    get "/api/warehouse", headers: manager_headers

    assert_response :success
    payload = json_response
    assert_equal 2, payload.length
    assert_equal ["Chips", "Water"], payload.map { |row| row["name"] }
    assert_equal [0, 5], payload.map { |row| row["qty"] }
  end

  test "adding stock persists through subsequent reads" do
    post "/api/warehouse/add_stock",
         params: { barcode: "333", name: "Soda", quantity: 4 }.to_json,
         headers: manager_headers

    assert_response :success

    get "/api/warehouse", headers: manager_headers
    assert_response :success

    row = json_response.find { |entry| entry["barcode"] == "333" }
    assert_not_nil row
    assert_equal 4, row["qty"]

    movement = WarehouseMovement.order(:id).last
    assert_equal "warehouse_receive", movement.movement_type
    assert_equal 4, movement.quantity_delta
    assert_equal 4, movement.balance_after
  end

  test "machine quantity update atomically decreases warehouse stock and increases machine inventory" do
    item = Item.create!(sku: "cola", name: "Cola", warehouse_quantity: 10, barcode: "444")
    machine = Machine.create!(id: "M-101", name: "Machine 101", lat: 1.0, lng: 2.0)

    post "/api/warehouse/update",
         params: { machine_id: machine.id, sku: item.sku, quantity: 3 }.to_json,
         headers: manager_headers

    assert_response :success
    assert_equal(
      {
        "status" => "success",
        "machine_id" => machine.id,
        "sku" => item.sku,
        "quantity" => 3
      },
      json_response
    )
    assert_equal 7, item.reload.warehouse_quantity
    assert_equal 3, MachineInventory.find_by!(machine_id: machine.id, item_id: item.id).quantity

    get "/api/inventory", headers: manager_headers
    assert_response :success
    assert_equal 3, json_response.fetch(machine.id).first.fetch("qty")
  end

  test "machine quantity update rejects fill when warehouse stock is insufficient" do
    item = Item.create!(sku: "juice", name: "Juice", warehouse_quantity: 1, barcode: "555")
    machine = Machine.create!(id: "M-102", name: "Machine 102", lat: 3.0, lng: 4.0)

    post "/api/warehouse/update",
         params: { machine_id: machine.id, sku: item.sku, quantity: 3 }.to_json,
         headers: manager_headers

    assert_response :unprocessable_entity
    assert_match(/Insufficient warehouse stock/, json_response.fetch("detail"))
    assert_equal 1, item.reload.warehouse_quantity
    assert_nil MachineInventory.find_by(machine_id: machine.id, item_id: item.id)
  end

  test "employee can update inventory for a machine on their assigned route" do
    employee = Employee.create!(id: "emp_route", name: "Route Employee", color: 0xFF123456, is_active: true)
    machine = Machine.create!(id: "M-300", name: "Machine 300", lat: 1.0, lng: 2.0)
    item = Item.create!(sku: "tea", name: "Tea", warehouse_quantity: 6, barcode: "666")
    route = Route.create!(employee: employee, employee_name: employee.name, distance_meters: 0, duration_seconds: 0)
    route.stops.create!(machine: machine, position: 0)

    with_stubbed_user(
      "id" => employee.id,
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      post "/api/warehouse/update",
           params: { machine_id: machine.id, sku: item.sku, quantity: 2 }.to_json,
           headers: employee_headers(user_id: employee.id)
    end

    assert_response :success
    assert_equal 4, item.reload.warehouse_quantity
    assert_equal 2, MachineInventory.find_by!(machine_id: machine.id, item_id: item.id).quantity
  end

  test "employee cannot update inventory for a machine outside their assigned route" do
    employee = Employee.create!(id: "emp_route", name: "Route Employee", color: 0xFF123456, is_active: true)
    assigned_machine = Machine.create!(id: "M-301", name: "Assigned Machine", lat: 1.0, lng: 2.0)
    other_machine = Machine.create!(id: "M-302", name: "Other Machine", lat: 3.0, lng: 4.0)
    item = Item.create!(sku: "chips", name: "Chips", warehouse_quantity: 8, barcode: "777")
    route = Route.create!(employee: employee, employee_name: employee.name, distance_meters: 0, duration_seconds: 0)
    route.stops.create!(machine: assigned_machine, position: 0)

    with_stubbed_user(
      "id" => employee.id,
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      post "/api/warehouse/update",
           params: { machine_id: other_machine.id, sku: item.sku, quantity: 1 }.to_json,
           headers: employee_headers(user_id: employee.id)
    end

    assert_response :forbidden
    assert_equal 8, item.reload.warehouse_quantity
    assert_nil MachineInventory.find_by(machine_id: other_machine.id, item_id: item.id)
  end

  test "employee update fails closed when auth id has no matching sql employee" do
    machine = Machine.create!(id: "M-400", name: "Machine 400", lat: 1.0, lng: 2.0)
    item = Item.create!(sku: "cookie", name: "Cookie", warehouse_quantity: 5, barcode: "1010")

    with_stubbed_user(
      "id" => "missing_employee",
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      post "/api/warehouse/update",
           params: { machine_id: machine.id, sku: item.sku, quantity: 1 }.to_json,
           headers: employee_headers(user_id: "missing_employee")
    end

    assert_response :forbidden
    assert_equal 5, item.reload.warehouse_quantity
    assert_nil MachineInventory.find_by(machine_id: machine.id, item_id: item.id)
  end
end
