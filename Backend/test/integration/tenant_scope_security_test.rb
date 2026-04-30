require "test_helper"

class TenantScopeSecurityTest < ActionDispatch::IntegrationTest
  setup do
    VendingTransaction.delete_all
    WarehouseMovement.delete_all
    MachineInventory.delete_all
    Shipment.delete_all
    Item.delete_all
    Stop.delete_all
    Route.delete_all
    Machine.delete_all
    Employee.delete_all
  end

  test "manager only sees machines for own organization" do
    org_a = create_test_organization(id: "org_aldervon")
    org_b = create_test_organization(id: "org_other", name: "Other Org")
    Machine.create!(id: "A-1", name: "A Machine", organization: org_a)
    Machine.create!(id: "B-1", name: "B Machine", organization: org_b)

    get "/api/machines", headers: manager_headers

    assert_response :success
    assert_equal ["A-1"], json_response.map { |row| row["id"] }
  end

  test "cross-tenant machine direct access returns not found" do
    create_test_organization(id: "org_aldervon")
    org_b = create_test_organization(id: "org_other", name: "Other Org")
    Machine.create!(id: "B-1", name: "B Machine", organization: org_b)

    get "/api/machines/B-1", headers: manager_headers

    assert_response :not_found
  end

  test "cross-tenant item direct access returns not found" do
    create_test_organization(id: "org_aldervon")
    org_b = create_test_organization(id: "org_other", name: "Other Org")
    item = Item.create!(sku: "other_sku", name: "Other Item", barcode: "other_barcode", organization: org_b)

    get "/api/items/#{item.id}", headers: manager_headers

    assert_response :not_found
  end

  test "cross-tenant transaction direct access returns not found" do
    create_test_organization(id: "org_aldervon")
    org_b = create_test_organization(id: "org_other", name: "Other Org")
    item = Item.create!(sku: "other_sku", name: "Other Item", barcode: "other_barcode", organization: org_b)
    machine = Machine.create!(id: "B-1", name: "B Machine", organization: org_b)
    transaction = VendingTransaction.create!(
      organization: org_b,
      item: item,
      machine: machine,
      amount: 2.50,
      status: VendingTransaction::STATUS_COMPLETED,
      completed_at: Time.current
    )

    get "/api/transactions/#{transaction.id}", headers: manager_headers

    assert_response :not_found
  end

  test "employee cannot read another employee route in same organization" do
    create_test_organization(id: "org_aldervon")
    employee = Employee.create!(id: "emp_self", name: "Self", organization_id: "org_aldervon")
    other = Employee.create!(id: "emp_other", name: "Other", organization_id: "org_aldervon")
    Route.create!(employee: other, employee_name: other.name, organization_id: "org_aldervon")

    with_stubbed_user(
      "id" => employee.id,
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/employees/#{other.id}/routes", headers: employee_headers(user_id: employee.id)
    end

    assert_response :forbidden
  end
end
