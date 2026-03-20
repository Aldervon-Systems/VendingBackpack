# frozen_string_literal: true

require "json"
require "fileutils"
require "securerandom"

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

      def organizations
        @organizations ||= load_json("organizations.json", [])
      end

      def whitelists
        @whitelists ||= load_json("whitelists.json", {})
      end

      def corporate_snapshots
        @corporate_snapshots ||= load_json("corporate_snapshots.json", {})
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
        @organizations = nil
        @whitelists = nil
        @corporate_snapshots = nil
      end

      def users
        @users ||= load_json("users.json", [])
      end

      def add_user(user_data)
        users << user_data
        save_json("users.json", users)
      end

      def update_user(user_data)
        idx = users.index { |u| u["id"] == user_data["id"] || u["email"] == user_data["email"] }
        if idx
          users[idx] = user_data
        else
          users << user_data
        end
        save_json("users.json", users)
      end

      def add_organization(org_data)
        organizations << org_data
        save_json("organizations.json", organizations)
      end

      def update_organization(org_data)
        idx = organizations.index { |o| o["id"] == org_data["id"] }
        if idx
          organizations[idx] = org_data
        else
          organizations << org_data
        end
        save_json("organizations.json", organizations)
      end

      def get_whitelist(org_id)
        whitelists[org_id] || []
      end

      def update_whitelist(org_id, emails)
        whitelists[org_id] = emails
        save_json("whitelists.json", whitelists)
      end

      def add_machine(machine_data)
        machines << machine_data
        save_json("machines.json", machines)
      end

      def save_json(name, data)
        path = FIXTURES_DIR.join(name)
        File.write(path, JSON.pretty_generate(data))
        reset! # Clear memoized variables so next load is fresh
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
