require "test_helper"

class UserPreferenceTest < ActiveSupport::TestCase
  setup do
    UserPreference.delete_all
  end

  test "is invalid without required fields" do
    preference = UserPreference.new

    assert_not preference.valid?
    assert_includes preference.errors[:user_id], "can't be blank"
    assert_includes preference.errors[:namespace], "can't be blank"
    assert_includes preference.errors[:value_json], "can't be blank"
  end

  test "enforces unique namespace per user" do
    UserPreference.create!(
      user_id: "user_admin",
      namespace: "corporate_view",
      version: 1,
      value_json: "{}"
    )

    duplicate = UserPreference.new(
      user_id: "user_admin",
      namespace: "corporate_view",
      version: 1,
      value_json: "{}"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:namespace], "has already been taken"
  end
end
