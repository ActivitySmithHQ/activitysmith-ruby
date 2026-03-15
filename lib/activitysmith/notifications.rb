# frozen_string_literal: true

module ActivitySmith
  class Notifications
    def initialize(api)
      @api = api
    end

    def send(request, opts = {})
      normalized = normalize_channels_target(request)
      assert_valid_media_actions!(normalized)
      @api.send_push_notification(normalized, opts)
    end

    # Backward-compatible alias.
    def send_push_notification(push_notification_request, opts = {})
      normalized = normalize_channels_target(push_notification_request)
      assert_valid_media_actions!(normalized)
      @api.send_push_notification(normalized, opts)
    end

    def method_missing(name, *args, &block)
      return @api.public_send(name, *args, &block) if @api.respond_to?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      @api.respond_to?(name, include_private) || super
    end

    private

    def normalize_channels_target(request)
      return request unless request.is_a?(Hash)

      hash = request.dup
      return hash if hash.key?(:target) || hash.key?("target")

      channels = hash.key?(:channels) ? hash.delete(:channels) : hash.delete("channels")
      normalized_channels = normalize_channels(channels)
      hash[:target] = { channels: normalized_channels } unless normalized_channels.empty?
      hash
    end

    def normalize_channels(channels)
      case channels
      when String
        channels.split(",").map(&:strip).reject(&:empty?)
      when Array
        channels.map { |channel| channel.is_a?(String) ? channel.strip : nil }.compact.reject(&:empty?)
      else
        []
      end
    end

    def assert_valid_media_actions!(request)
      media = request_value(request, :media)
      actions = request_value(request, :actions)
      has_media = media.is_a?(String) ? !media.strip.empty? : !media.nil?
      has_actions = actions.respond_to?(:empty?) ? !actions.empty? : !actions.nil?

      return unless has_media && has_actions

      raise ArgumentError, "ActivitySmith: media cannot be combined with actions"
    end

    def request_value(request, key)
      if request.is_a?(Hash)
        return request[key] if request.key?(key)
        return request[key.to_s] if request.key?(key.to_s)

        return nil
      end

      return request.public_send(key) if request.respond_to?(key)

      nil
    end
  end
end
