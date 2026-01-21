# frozen_string_literal: true

require "json"

module Fixtures
  class MutableStore
    FIXTURES_DIR = Rails.root.join("data", "fixtures")

    class << self
      def items
        @items ||= load_json("items.json", [])
      end

      def transactions
        @transactions ||= load_json("transactions.json", [])
      end

      def machines
        @machines ||= load_json("machines.json", [])
      end

      def employee_routes
        @employee_routes ||= load_json("employee_routes.json", [])
      end

      def inventory
        @inventory ||= load_json("inventory.json", {})
      end

      def update_inventory_item(machine_id, sku, new_qty)
        return unless inventory[machine_id]
        item = inventory[machine_id].find { |i| i["sku"] == sku }
        if item
          item["qty"] = new_qty
        end
      end

      def update_route(route)
        idx = employee_routes.index { |r| r["id"] == route["id"] }
        if idx
          employee_routes[idx] = route
        else
          employee_routes << route
        end
      end

      def reset!
        @items = nil
        @transactions = nil
        @machines = nil
        @employee_routes = nil
        @inventory = nil
      end

      def load_json(name, fallback)
        path = FIXTURES_DIR.join(name)
        return fallback unless path.exist?

        JSON.parse(path.read)
      rescue JSON::ParserError
        fallback
      end

      private
    end
  end
end
