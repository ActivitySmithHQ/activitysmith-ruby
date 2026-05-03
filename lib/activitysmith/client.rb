# frozen_string_literal: true

module ActivitySmith
  class Client
    attr_reader :notifications, :live_activities, :metrics

    def initialize(api_key:)
      raise ArgumentError, "ActivitySmith: api_key is required" if api_key.to_s.strip.empty?

      load_generated_client!

      config = OpenapiClient::Configuration.new
      config.access_token = api_key
      config.user_agent = VersionedUserAgent.value if config.respond_to?(:user_agent=)

      api_client = OpenapiClient::ApiClient.new(config)
      api_client.user_agent = VersionedUserAgent.value
      api_client.default_headers["X-ActivitySmith-SDK"] = "ruby-v#{ActivitySmith::VERSION}"
      @notifications = Notifications.new(OpenapiClient::PushNotificationsApi.new(api_client))
      @live_activities = LiveActivities.new(OpenapiClient::LiveActivitiesApi.new(api_client))
      @metrics = Metrics.new(OpenapiClient::MetricsApi.new(api_client))
    end

    private

    def load_generated_client!
      return if generated_client_present?

      generated_root = File.expand_path("../../generated", __dir__)
      $LOAD_PATH.unshift(generated_root) unless $LOAD_PATH.include?(generated_root)

      generated_entrypoint = File.join(generated_root, "activitysmith_openapi")
      require generated_entrypoint if File.exist?("#{generated_entrypoint}.rb")

      return if generated_client_present?

      raise RuntimeError,
            "Generated Ruby client not found. Run SDK regeneration so /generated contains OpenAPI output."
    end

    def generated_client_present?
      missing = [
        "OpenapiClient::Configuration",
        "OpenapiClient::ApiClient",
        "OpenapiClient::PushNotificationsApi",
        "OpenapiClient::LiveActivitiesApi",
        "OpenapiClient::MetricsApi"
      ].reject { |name| constant_defined?(name) }

      missing.empty?
    end

    def constant_defined?(name)
      Object.const_get(name)
      true
    rescue NameError
      false
    end
  end
end
