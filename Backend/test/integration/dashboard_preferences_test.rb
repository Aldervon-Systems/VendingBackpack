require "test_helper"

class DashboardPreferencesTest < ActionDispatch::IntegrationTest
  setup do
    UserPreference.delete_all
  end

  test "employee gets default dashboard preferences when no record exists" do
    with_stubbed_user(
      "id" => "emp-07",
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/dashboard/preferences", headers: employee_headers(user_id: "emp-07")
    end

    assert_response :success
    assert_equal %w[systemOverview networkNodes routeNotes], json_response["visibleSections"]
    assert_equal %w[systemOverview networkNodes routeNotes], json_response["sectionOrder"]
  end

  test "dashboard preferences save and reload for employee" do
    payload = {
      visibleSections: %w[routeNotes systemOverview],
      sectionOrder: %w[routeNotes systemOverview]
    }

    with_stubbed_user(
      "id" => "emp-07",
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      put "/api/dashboard/preferences", params: payload, as: :json, headers: employee_headers(user_id: "emp-07")
      assert_response :success

      get "/api/dashboard/preferences", headers: employee_headers(user_id: "emp-07")
    end

    assert_response :success
    assert_equal %w[routeNotes systemOverview], json_response["visibleSections"]
    assert_equal %w[routeNotes systemOverview networkNodes], json_response["sectionOrder"]
  end

  test "dashboard preferences are isolated per user" do
    UserPreferences::DashboardLayoutService.new.save(
      user_id: "user_one",
      payload: { "visibleSections" => ["routeNotes"] }
    )

    with_stubbed_user(
      "id" => "user_two",
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/dashboard/preferences", headers: employee_headers(user_id: "user_two")
    end

    assert_response :success
    assert_equal %w[systemOverview networkNodes routeNotes], json_response["visibleSections"]
  end

  test "dashboard preferences normalize malformed stored payloads" do
    UserPreference.create!(
      user_id: "emp-07",
      namespace: UserPreferences::DashboardLayoutService::NAMESPACE,
      version: 1,
      value_json: JSON.generate(
        "visibleSections" => ["routeNotes", "bad", "routeNotes"],
        "sectionOrder" => ["networkNodes"]
      )
    )

    with_stubbed_user(
      "id" => "emp-07",
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/dashboard/preferences", headers: employee_headers(user_id: "emp-07")
    end

    assert_response :success
    assert_equal ["routeNotes"], json_response["visibleSections"]
    assert_equal %w[networkNodes systemOverview routeNotes], json_response["sectionOrder"]
  end
end
