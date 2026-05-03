# frozen_string_literal: true

module ActivitySmith
  class Metrics
    def initialize(api)
      @api = api
    end

    def update(key, value_or_request, timestamp: nil, **opts)
      @api.update_metric_value(key, metric_value_request(value_or_request, timestamp), opts)
    end

    # Backward-compatible generated-style alias.
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
