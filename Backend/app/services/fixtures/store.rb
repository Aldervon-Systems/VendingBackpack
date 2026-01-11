# frozen_string_literal: true

require "json"

module Fixtures
  class Store
    FIXTURES_DIR = Rails.root.join("data", "fixtures")

    def initialize
      @cache = {}
    end

    def read_json(name)
      @cache[name] ||= begin
        path = FIXTURES_DIR.join(name)
        JSON.parse(path.read)
      end
    end
  end
end
