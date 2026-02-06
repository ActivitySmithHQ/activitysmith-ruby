# frozen_string_literal: true

require_relative "test_helper"

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
  rescue RuntimeError => error
    skip "Generated OpenAPI client is not present yet." if error.message.include?("Generated Ruby client not found")

    raise
  end
end
