require "test_helper"

class ItemsHardeningTest < ActionDispatch::IntegrationTest
  setup do
    WarehouseMovement.delete_all
    MachineInventory.delete_all
    Item.delete_all
  end

  test "items index and barcode lookup resolve from SQL-backed items" do
    item = Item.create!(
      sku: "sparkling_water",
      name: "Sparkling Water",
      warehouse_quantity: 12,
      barcode: "888",
      price: 1.75,
      slot_number: "B5",
      is_available: true
    )

    get "/api/items", headers: manager_headers
    assert_response :success
    assert_equal [item.id], json_response.map { |row| row["id"] }

    get "/api/items/888", headers: manager_headers
    assert_response :success
    assert_equal "sparkling_water", json_response.fetch("sku")
    assert_equal "Sparkling Water", json_response.fetch("name")
    assert_equal 12, json_response.fetch("qty")
  end

  test "updating item quantity persists and records a warehouse adjustment" do
    item = Item.create!(
      sku: "protein_bar",
      name: "Protein Bar",
      warehouse_quantity: 3,
      barcode: "999",
      price: 2.25,
      slot_number: "A1",
      is_available: true
    )

    put "/api/items/#{item.id}",
        params: { quantity: 7 }.to_json,
        headers: manager_headers

    assert_response :success
    assert_equal 7, item.reload.warehouse_quantity

    movement = WarehouseMovement.order(:id).last
    assert_equal item.id, movement.item_id
    assert_equal "warehouse_adjustment", movement.movement_type
    assert_equal 4, movement.quantity_delta
    assert_equal 7, movement.balance_after
  end

  test "delete is blocked when warehouse stock remains" do
    item = Item.create!(
      sku: "electrolyte",
      name: "Electrolyte",
      warehouse_quantity: 2,
      barcode: "1212",
      price: 3.00,
      slot_number: "C3",
      is_available: true
    )

    delete "/api/items/#{item.id}", headers: manager_headers

    assert_response :unprocessable_entity
    assert_match(/warehouse stock remains/, json_response.fetch("detail"))
    assert Item.exists?(item.id)
  end

  test "delete is blocked when machine inventory rows exist" do
    item = Item.create!(
      sku: "granola",
      name: "Granola",
      warehouse_quantity: 0,
      barcode: "1313",
      price: 1.50,
      slot_number: "D4",
      is_available: true
    )
    machine = Machine.create!(id: "M-500", name: "Machine 500", lat: 1.0, lng: 2.0)
    MachineInventory.create!(machine: machine, item: item, quantity: 0)

    delete "/api/items/#{item.id}", headers: manager_headers

    assert_response :unprocessable_entity
    assert_match(/machine inventory rows remain/, json_response.fetch("detail"))
    assert Item.exists?(item.id)
  end

  test "delete is blocked when warehouse movement history exists" do
    item = Item.create!(
      sku: "kombucha",
      name: "Kombucha",
      warehouse_quantity: 0,
      barcode: "1414",
      price: 4.00,
      slot_number: "E5",
      is_available: true
    )
    WarehouseMovement.create!(
      item: item,
      movement_type: "warehouse_adjustment",
      quantity_delta: 1,
      balance_after: 0,
      reference_code: "manual_test"
    )

    delete "/api/items/#{item.id}", headers: manager_headers

    assert_response :unprocessable_entity
    assert_match(/movement history exists/, json_response.fetch("detail"))
    assert Item.exists?(item.id)
  end

  test "delete succeeds only when no stock rows or movement rows remain" do
    item = Item.create!(
      sku: "seltzer",
      name: "Seltzer",
      warehouse_quantity: 0,
      barcode: "1515",
      price: 1.25,
      slot_number: "F6",
      is_available: false
    )

    delete "/api/items/#{item.id}", headers: manager_headers

    assert_response :no_content
    refute Item.exists?(item.id)
  end
end
