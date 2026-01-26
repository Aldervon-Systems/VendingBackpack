# frozen_string_literal: true

module Fixtures
  class MockApi
    def initialize(store: Store.new)
      @store = store
    end

    def find_user(email)
      users.find { |u| u.fetch("email").downcase == email.to_s.downcase }
    end

    def employees
      Fixtures::MutableStore.load_json("employees.json", [])
    end

    def locations
      @store.read_json("locations.json")
    end

    def warehouse_inventory
      Fixtures::MutableStore.inventory
    end

    def daily_stats
      @store.read_json("daily_stats.json")
    end

    def find_item_by_barcode(barcode)
      warehouse_inventory.each_value do |items|
        next unless items.is_a?(Array)

        items.each do |item|
          return item if item["barcode"] == barcode
        end
      end
      {}
    end

    private

    def users
      Fixtures::MutableStore.users
    end
  end
end
