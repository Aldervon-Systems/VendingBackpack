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

      def reset!
        @items = nil
        @transactions = nil
        @machines = nil
        @employee_routes = nil
      end

      private

      def load_json(name, fallback)
        path = FIXTURES_DIR.join(name)
        return fallback unless path.exist?

        JSON.parse(path.read)
      rescue JSON::ParserError
        fallback
      end
    end
  end
end
