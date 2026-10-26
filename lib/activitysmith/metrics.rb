# frozen_string_literal: true

module ActivitySmith
  class Metrics
    def initialize(api)
      @api = api
    end

    def update(key, value_or_request, timestamp: nil, **opts)
      @api.update_metric_value(key, metric_value_request(value_or_request, timestamp), opts)
    end

    # Creates the metric, or updates the fields sent for an existing one.
    # Omitted fields keep their current values, so it is safe to call on every start.
    def create(key, definition = nil, label: nil, format: nil, currency_code: nil, unit: nil, unit_spacing: nil, **opts)
      fields = { label: label, format: format, currency_code: currency_code, unit: unit, unit_spacing: unit_spacing }.compact
      request = fields.empty? ? definition : (definition || {}).to_h.merge(fields)
      request = nil if request.respond_to?(:empty?) && request.empty?
      opts = opts.merge(metric_upsert_request: request) unless request.nil?
      @api.upsert_metric(key, opts)
    end

    # Backward-compatible generated-style aliases.
    def upsert_metric(key, opts = {})
      @api.upsert_metric(key, opts)
    end

    def update_metric_value(key, metric_value_update_request, opts = {})
      @api.update_metric_value(key, metric_value_update_request, opts)
    end

    def method_missing(name, *args, &block)
      return @api.public_send(name, *args, &block) if @api.respond_to?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      @api.respond_to?(name, include_private) || super
    end

    private

    def metric_value_request(value_or_request, timestamp)
      if value_or_request.is_a?(Hash) && (value_or_request.key?(:value) || value_or_request.key?("value"))
        hash = value_or_request.dup
        hash[:timestamp] = timestamp unless timestamp.nil?
        return hash
      end

      hash = { value: value_or_request }
      hash[:timestamp] = timestamp unless timestamp.nil?
      hash
    end
  end
end
