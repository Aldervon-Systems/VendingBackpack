require "test_helper"

class CorporateAccessTest < ActionDispatch::IntegrationTest
  test "manager can fetch corporate snapshot for their organization" do
    with_stubbed_user(
      "id" => "user_admin",
      "role" => "manager",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/corporate", headers: manager_headers
    end

    assert_response :success

    payload = json_response

    assert_equal "Aldervon Systems", payload.dig("meta", "organizationName")
    assert_equal "January-March 2026", payload.dig("meta", "reportingPeriod")
    assert_kind_of Array, payload["revenueBudgetSeries"]
    assert_kind_of Array, payload["profitSeries"]
    assert_kind_of Array, payload["rollingSalesSeries"]
    assert_kind_of Array, payload["budgetVarianceRows"]
    assert_kind_of Array, payload["machineProfitRows"]
    assert_equal 5, payload["revenueBudgetSeries"].length
    assert_equal 6, payload["machineProfitRows"].length
  end

  test "employee is forbidden from fetching corporate snapshot" do
    with_stubbed_user(
      "id" => "emp-07",
      "role" => "employee",
      "organization_id" => "org_aldervon"
    ) do
      get "/api/corporate", headers: employee_headers(user_id: "emp-07")
    end

    assert_response :forbidden
    assert_equal "Forbidden", json_response.fetch("detail")
  end
end
