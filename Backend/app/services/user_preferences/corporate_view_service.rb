# frozen_string_literal: true

require "json"

module UserPreferences
  class CorporateViewService
    NAMESPACE = "corporate_view"
    VERSION = 1
    WIDGET_IDS = %w[revenueBudget profitByMachine rollingSales budgetVariance machineProfit].freeze
    BUDGET_VARIANCE_SORT_COLUMNS = %w[period budget revenue variance variancePercent].freeze
    MACHINE_PROFIT_SORT_COLUMNS = %w[machineName location revenue estimatedCost grossProfit marginPercent].freeze
    SORT_DIRECTIONS = %w[asc desc].freeze

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
        "visibleWidgets" => WIDGET_IDS.dup,
        "widgetOrder" => WIDGET_IDS.dup,
        "tableSorts" => {
          "budgetVariance" => {
            "column" => "variance",
            "direction" => "desc",
          },
          "machineProfit" => {
            "column" => "grossProfit",
            "direction" => "desc",
          },
        },
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
        "visibleWidgets" => normalize_visible_widgets(candidate["visibleWidgets"]),
        "widgetOrder" => normalize_widget_order(candidate["widgetOrder"]),
        "tableSorts" => normalize_table_sorts(candidate["tableSorts"]),
      }
    end

    def normalize_visible_widgets(value)
      return WIDGET_IDS.dup unless value.is_a?(Array)

      unique_widget_ids(value)
    end

    def normalize_widget_order(value)
      normalized = value.is_a?(Array) ? unique_widget_ids(value) : []
      normalized + WIDGET_IDS.reject { |widget_id| normalized.include?(widget_id) }
    end

    def normalize_table_sorts(value)
      candidate = value.is_a?(Hash) ? value : {}
      default_sorts = defaults["tableSorts"]

      {
        "budgetVariance" => {
          "column" => normalize_enum(
            candidate.dig("budgetVariance", "column"),
            BUDGET_VARIANCE_SORT_COLUMNS,
            default_sorts.dig("budgetVariance", "column"),
          ),
          "direction" => normalize_enum(
            candidate.dig("budgetVariance", "direction"),
            SORT_DIRECTIONS,
            default_sorts.dig("budgetVariance", "direction"),
          ),
        },
        "machineProfit" => {
          "column" => normalize_enum(
            candidate.dig("machineProfit", "column"),
            MACHINE_PROFIT_SORT_COLUMNS,
            default_sorts.dig("machineProfit", "column"),
          ),
          "direction" => normalize_enum(
            candidate.dig("machineProfit", "direction"),
            SORT_DIRECTIONS,
            default_sorts.dig("machineProfit", "direction"),
          ),
        },
      }
    end

    def unique_widget_ids(values)
      seen = {}

      values.each_with_object([]) do |value, result|
        next unless WIDGET_IDS.include?(value)
        next if seen[value]

        seen[value] = true
        result << value
      end
    end

    def normalize_enum(value, allowed_values, fallback)
      allowed_values.include?(value) ? value : fallback
    end
  end
end
