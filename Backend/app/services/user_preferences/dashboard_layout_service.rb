# frozen_string_literal: true

require "json"

module UserPreferences
  class DashboardLayoutService
    NAMESPACE = "dashboard_layout"
    VERSION = 1
    SECTION_IDS = %w[systemOverview networkNodes routeNotes].freeze

    def initialize(store: Store.new, logger: Rails.logger)
      @store = store
      @logger = logger
    end

    def load(user_id:)
      record = @store.load(user_id: user_id, namespace: NAMESPACE)
      return defaults.deep_dup if record.nil?

      normalize_from_record(record, user_id: user_id)
    end

    def save(user_id:, payload:)
      normalized = normalize_payload(payload)

      @store.save(
        user_id: user_id,
        namespace: NAMESPACE,
        version: VERSION,
        value_json: JSON.generate(normalized),
      )

      @logger.info("[preferences] saved namespace=#{NAMESPACE} user_id=#{user_id}")
      normalized
    end

    private

    def defaults
      {
        "visibleSections" => SECTION_IDS.dup,
        "sectionOrder" => SECTION_IDS.dup,
      }
    end

    def normalize_from_record(record, user_id:)
      payload = parse_payload(record.value_json, user_id: user_id)
      normalized = migrate(record.version, payload)

      if normalized != payload
        @logger.warn("[preferences] normalized namespace=#{NAMESPACE} user_id=#{user_id} version=#{record.version}")
      end

      normalized
    end

    def parse_payload(raw_json, user_id:)
      JSON.parse(raw_json)
    rescue JSON::ParserError
      @logger.warn("[preferences] invalid_json namespace=#{NAMESPACE} user_id=#{user_id}")
      {}
    end

    def migrate(version, payload)
      case version.to_i
      when VERSION
        normalize_payload(payload)
      else
        normalize_payload(payload)
      end
    end

    def normalize_payload(payload)
      candidate = payload.is_a?(Hash) ? payload : {}

      {
        "visibleSections" => normalize_visible_sections(candidate["visibleSections"]),
        "sectionOrder" => normalize_section_order(candidate["sectionOrder"]),
      }
    end

    def normalize_visible_sections(value)
      return SECTION_IDS.dup unless value.is_a?(Array)

      unique_section_ids(value)
    end

    def normalize_section_order(value)
      normalized = value.is_a?(Array) ? unique_section_ids(value) : []
      normalized + SECTION_IDS.reject { |section_id| normalized.include?(section_id) }
    end

    def unique_section_ids(values)
      seen = {}

      values.each_with_object([]) do |value, result|
        next unless SECTION_IDS.include?(value)
        next if seen[value]

        seen[value] = true
        result << value
      end
    end
  end
end
