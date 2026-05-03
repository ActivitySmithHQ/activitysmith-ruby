# frozen_string_literal: true

require_relative "test_helper"

module OpenapiClient
  class Configuration
    attr_accessor :access_token, :user_agent
  end

  class ApiClient
    attr_reader :config
    attr_accessor :default_headers

    def initialize(config)
      @config = config
      @default_headers = { "User-Agent" => "OpenAPI-Generator/test" }
    end

    def user_agent=(user_agent)
      @default_headers["User-Agent"] = user_agent
    end
  end

  class PushNotificationsApi
    attr_reader :api_client

    def initialize(api_client)
      @api_client = api_client
    end
  end

  class LiveActivitiesApi
    attr_reader :api_client

    def initialize(api_client)
      @api_client = api_client
    end
  end

  class MetricsApi
    attr_reader :api_client

    def initialize(api_client)
      @api_client = api_client
    end
  end
end

class ClientTest < Minitest::Test
  def test_requires_api_key
    error = assert_raises(ArgumentError) do
      ActivitySmith::Client.new(api_key: "")
    end

    assert_equal "ActivitySmith: api_key is required", error.message
  end

  def test_constructs_when_generated_client_is_present
    client = ActivitySmith::Client.new(api_key: "test-api-key")

    refute_nil client.notifications
    refute_nil client.live_activities
    assert_respond_to client.notifications, :send
    assert_respond_to client.live_activities, :start
    assert_respond_to client.live_activities, :update
    assert_respond_to client.live_activities, :end
    assert_respond_to client.live_activities, :stream
    assert_respond_to client.live_activities, :end_stream
    refute_nil client.metrics
    assert_respond_to client.metrics, :update

    metrics_api = client.metrics.instance_variable_get(:@api)
    assert_equal "ruby-v#{ActivitySmith::VERSION}", metrics_api.api_client.default_headers["X-ActivitySmith-SDK"]
    assert_equal ActivitySmith::VersionedUserAgent.value, metrics_api.api_client.default_headers["User-Agent"]
  rescue RuntimeError => error
    skip "Generated OpenAPI client is not present yet." if error.message.include?("Generated Ruby client not found")

    raise
  end
end
