ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: 1)
end

class ActionDispatch::IntegrationTest
  private

  def with_stubbed_user(user)
    fake_api = Object.new
    fake_api.define_singleton_method(:find_user_by_id) do |id|
      id.to_s == user.fetch("id").to_s ? user : nil
    end

    Fixtures::MockApi.stub(:new, fake_api) do
      yield
    end
  end

  def manager_headers
    auth_headers(user_id: "user_admin", role: "manager", organization_id: "org_aldervon")
  end

  def employee_headers(user_id:, organization_id: "org_aldervon")
    auth_headers(user_id: user_id, role: "employee", organization_id: organization_id)
  end

  def auth_headers(user_id:, role:, organization_id:)
    token = Rails.application.message_verifier(:access_token).generate(
      {
        "sub" => user_id,
        "role" => role,
        "organization_id" => organization_id,
        "exp" => Time.now.to_i + 3600
      }
    )

    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  def json_response
    JSON.parse(response.body)
  end
end
