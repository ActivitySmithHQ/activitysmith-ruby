# frozen_string_literal: true

module ActivitySmith
  class Client
    attr_reader :notifications, :live_activities

    def initialize(api_key:, base_url: nil)
      raise ArgumentError, "ActivitySmith: api_key is required" if api_key.to_s.strip.empty?

      load_generated_client!

      config = OpenapiClient::Configuration.new
      config.access_token = api_key
      config.host = base_url.to_s.sub(%r{/+$}, "") unless base_url.to_s.strip.empty?

      api_client = OpenapiClient::ApiClient.new(config)
      @notifications = Notifications.new(OpenapiClient::PushNotificationsApi.new(api_client))
      @live_activities = LiveActivities.new(OpenapiClient::LiveActivitiesApi.new(api_client))
    end

    private

    def load_generated_client!
      generated_entrypoint = File.expand_path("../../generated/openapi_client", __dir__)
      require generated_entrypoint if File.exist?("#{generated_entrypoint}.rb")

      required_constants = [
        "OpenapiClient::Configuration",
        "OpenapiClient::ApiClient",
        "OpenapiClient::PushNotificationsApi",
        "OpenapiClient::LiveActivitiesApi"
      ]

      missing = required_constants.reject { |name| constant_defined?(name) }
      return if missing.empty?

      raise RuntimeError,
            "Generated Ruby client not found. Run SDK regeneration so /generated contains OpenAPI output."
    end

    def constant_defined?(name)
      Object.const_get(name)
      true
    rescue NameError
      false
    end
  end
end
