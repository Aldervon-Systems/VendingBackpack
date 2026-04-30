# frozen_string_literal: true

require "json"

class SeedCorporateSnapshots
  FILE_PATH = Rails.root.join("data", "fixtures", "corporate_snapshots.json")

  class << self
    def fetch(organization_id)
      return nil unless FILE_PATH.exist?

      payload = JSON.parse(FILE_PATH.read)
      snapshot = payload[organization_id.to_s]
      snapshot.is_a?(Hash) ? snapshot : nil
    rescue JSON::ParserError
      nil
    end
  end
end
