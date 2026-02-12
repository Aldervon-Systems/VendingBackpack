# frozen_string_literal: true

require "json"
require "fileutils"

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
      
      def central_stock
        @central_stock ||= load_json("central_stock.json", [])
      end

      def shipments
        @shipments ||= load_json("shipments.json", [])
      end

      def update_inventory_item(machine_id, sku, new_qty)
        return unless inventory[machine_id]
        item = inventory[machine_id].find { |i| i["sku"] == sku }
        if item
          item["qty"] = new_qty
        end
      end

      def add_to_central_stock(barcode, name, qty_to_add)
        item = central_stock.find { |i| i["barcode"] == barcode }
        if item
          item["qty"] += qty_to_add
        else
          sku = name.to_s.downcase.gsub(' ', '_')
          central_stock << {
            "sku" => sku,
            "name" => name,
            "qty" => qty_to_add,
            "barcode" => barcode
          }
        end
        save_json("central_stock.json", central_stock)
      end

      def update_route(route)
        idx = employee_routes.index { |r| r["id"] == route["id"] }
        if idx
          employee_routes[idx] = route
        else
          employee_routes << route
        end
        save_json("employee_routes.json", employee_routes)
      end

      def reset!
        @items = nil
        @transactions = nil
        @machines = nil
        @employee_routes = nil
        @inventory = nil
        @users = nil
        @central_stock = nil
        @shipments = nil
      end

      def users
        @users ||= load_json("users.json", [])
      end

      def add_user(user_data)
        users << user_data
        save_json("users.json", users)
      end

      def save_json(name, data)
        path = FIXTURES_DIR.join(name)
        File.write(path, JSON.pretty_generate(data))
      end

      def load_json(name, fallback)
        FileUtils.mkdir_p(FIXTURES_DIR) unless Dir.exist?(FIXTURES_DIR)
        path = FIXTURES_DIR.join(name)
        return fallback unless path.exist?

        JSON.parse(path.read)
      rescue => e
        Rails.logger.error "Error loading JSON #{name}: #{e.message}"
        fallback
      end

      private
    end
  end
end
