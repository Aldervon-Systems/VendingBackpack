# frozen_string_literal: true

module Fixtures
  class MockApi
    def initialize(store: Store.new)
      @store = store
    end

    def find_user(email)
      users.find { |u| u.fetch("email").downcase == email.to_s.downcase }
    end

    def find_user_by_id(id)
      users.find { |u| u["id"].to_s == id.to_s }
    end

    def employees
      Fixtures::MutableStore.load_json("employees.json", [])
    end

    def locations
      static_locs = @store.read_json("locations.json") || []
      dynamic_machines = Fixtures::MutableStore.machines.select { |m| m["lat"] && m["lng"] }
      
      # Map machines to location format if needed, but they seem to share lat/lng/name/id
      static_locs + dynamic_machines
    end

    def warehouse_inventory
      Fixtures::MutableStore.central_stock
    end

    def daily_stats
      @store.read_json("daily_stats.json")
    end

    def corporate_snapshot(org_id)
      Fixtures::MutableStore.corporate_snapshots[org_id.to_s]
    end

    def find_item_by_barcode(barcode)
      warehouse_inventory.find { |item| item["barcode"] == barcode } || {}
    end

    def find_organization(id)
      organizations.find { |o| o["id"] == id }
    end

    def search_organizations(query)
      organizations.select { |o| o["name"].downcase.include?(query.to_s.downcase) }
    end

    def organization_whitelist(org_id)
      Fixtures::MutableStore.whitelists[org_id] || []
    end

    def is_whitelisted?(org_id, email)
      whitelist = Fixtures::MutableStore.whitelists[org_id.to_s] || []
      whitelist.any? { |e| e.downcase == email.to_s.downcase }
    end

    private

    def users
      Fixtures::MutableStore.users
    end

    def organizations
      Fixtures::MutableStore.organizations
    end
  end
end
