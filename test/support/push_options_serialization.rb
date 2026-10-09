# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class PushOptionsTest < Minitest::Test
  def test_serialized_options_for_hash_keywords_model_and_legacy
    ActivitySmith::Client.new(api_key: 'mock-only')
    [false, true].each do |with_icon|
      [nil, *ActivitySmith::PushInterruptionLevel::VALUES].each do |level|
        [:send, :send_push_notification].each do |method|
          [:hash, :keywords, :model].each do |form|
            fields = {title: 'GitHub', subtitle: 'Build status', tags: ['ci']}
            fields[:icon] = 'https://example.com/github.png' if with_icon
            fields[:interruption_level] = level unless level.nil?
            captured = []
            api_client = OpenapiClient::ApiClient.new
            api_client.define_singleton_method(:call_api) do |http_method, path, opts = {}|
              request = build_request(http_method, path, opts)
              captured << JSON.parse(request.options[:body])
              [nil, 200, {}]
            end
            notifications = ActivitySmith::Notifications.new(OpenapiClient::PushNotificationsApi.new(api_client))
            case form
            when :keywords
              notifications.public_send(method, **fields, channels: ['ops'])
            when :model
              notifications.public_send(method, OpenapiClient::PushNotificationRequest.new(fields.merge(target: {channels: ['ops']})))
            else
              notifications.public_send(method, fields.merge(channels: ['ops']))
            end
            assert_equal JSON.parse(JSON.generate(fields.merge(target: {channels: ['ops']}))), captured.last
          end
        end
      end
    end
  end

  def test_invalid_level_rejected
    api = Object.new
    assert_raises(ArgumentError) { ActivitySmith::Notifications.new(api).send(title: 'Test', interruption_level: 'timeSensitive') }
    assert_raises(ArgumentError) { ActivitySmith::Notifications.new(api).send(title: 'Test', interruption_level: 'critical') }
  end
end
