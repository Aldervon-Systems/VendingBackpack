# frozen_string_literal: true

module UserPreferences
  class Store
    def load(user_id:, namespace:)
      UserPreference.find_by(user_id: user_id.to_s, namespace: namespace.to_s)
    end

    def save(user_id:, namespace:, version:, value_json:)
      record = UserPreference.find_or_initialize_by(
        user_id: user_id.to_s,
        namespace: namespace.to_s,
      )

      record.version = version
      record.value_json = value_json
      record.save!
      record
    end
  end
end
