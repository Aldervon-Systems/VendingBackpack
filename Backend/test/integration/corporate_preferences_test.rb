require "test_helper"

class CorporatePreferencesTest < ActionDispatch::IntegrationTest
  setup do
    UserPreference.delete_all
  end

  test "manager gets default corporate preferences when no record exists" do
    with_stubbed_user(
      "id" => "user_admin",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/corporate/preferences", headers: manager_headers
    end

    assert_response :success
    assert_equal %w[revenueBudget profitByMachine rollingSales budgetVariance machineProfit], json_response["visibleWidgets"]
    assert_equal "variance", json_response.dig("tableSorts", "budgetVariance", "column")
    assert_equal "grossProfit", json_response.dig("tableSorts", "machineProfit", "column")
  end

  test "manager saves and reloads corporate preferences" do
    payload = {
      visibleWidgets: %w[rollingSales machineProfit],
      widgetOrder: %w[machineProfit rollingSales revenueBudget],
      tableSorts: {
        budgetVariance: { column: "period", direction: "asc" },
        machineProfit: { column: "location", direction: "asc" }
      }
    }

    with_stubbed_user(
      "id" => "user_admin",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    ) do
      put "/api/corporate/preferences", params: payload, as: :json, headers: manager_headers
      assert_response :success

      get "/api/corporate/preferences", headers: manager_headers
    end

    assert_response :success
    assert_equal %w[rollingSales machineProfit], json_response["visibleWidgets"]
    assert_equal %w[machineProfit rollingSales revenueBudget profitByMachine budgetVariance], json_response["widgetOrder"]
    assert_equal "period", json_response.dig("tableSorts", "budgetVariance", "column")
    assert_equal "location", json_response.dig("tableSorts", "machineProfit", "column")
  end

  test "corporate preferences are isolated per user" do
    UserPreferences::CorporateViewService.new.save(
      user_id: "user_one",
      payload: { "visibleWidgets" => ["machineProfit"] }
    )

    with_stubbed_user(
      "id" => "user_two",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/corporate/preferences", headers: auth_headers(user_id: "user_two", role: "manager", organization_id: "org_aldervon")
    end

    assert_response :success
    assert_equal %w[revenueBudget profitByMachine rollingSales budgetVariance machineProfit], json_response["visibleWidgets"]
  end

  test "employee cannot access corporate preferences" do
    with_stubbed_user(
      "id" => "emp-07",
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/corporate/preferences", headers: employee_headers(user_id: "emp-07")
    end

    assert_response :forbidden
  end

  test "corporate preferences normalize malformed stored payloads" do
    UserPreference.create!(
      user_id: "user_admin",
      namespace: UserPreferences::CorporateViewService::NAMESPACE,
      version: 1,
      value_json: JSON.generate(
        "visibleWidgets" => ["machineProfit", "machineProfit", "badWidget"],
        "widgetOrder" => ["rollingSales"],
        "tableSorts" => {
          "budgetVariance" => { "column" => "bad", "direction" => "asc" },
          "machineProfit" => { "column" => "grossProfit", "direction" => "wrong" }
        }
      )
    )

    with_stubbed_user(
      "id" => "user_admin",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/corporate/preferences", headers: manager_headers
    end

    assert_response :success
    assert_equal ["machineProfit"], json_response["visibleWidgets"]
    assert_equal %w[rollingSales revenueBudget profitByMachine budgetVariance machineProfit], json_response["widgetOrder"]
    assert_equal "variance", json_response.dig("tableSorts", "budgetVariance", "column")
    assert_equal "desc", json_response.dig("tableSorts", "machineProfit", "direction")
  end
end
