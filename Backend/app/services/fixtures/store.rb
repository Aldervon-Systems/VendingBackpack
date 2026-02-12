# frozen_string_literal: true

require "json"
require "fileutils"

module Fixtures
  class Store
    FIXTURES_DIR = Rails.root.join("data", "fixtures")

    def initialize
      @cache = {}
    end

    def read_json(name)
      FileUtils.mkdir_p(FIXTURES_DIR) unless Dir.exist?(FIXTURES_DIR)
      @cache[name] ||= begin
        path = FIXTURES_DIR.join(name)
        return {} unless path.exist?
        JSON.parse(path.read)
      rescue => e
        Rails.logger.error "Error reading JSON #{name} in Store: #{e.message}"
        {}
      end
    end
  end
end
