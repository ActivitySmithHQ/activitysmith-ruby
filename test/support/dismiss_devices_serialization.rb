# frozen_string_literal: true

require_relative '../test_helper'
require 'json'
require 'stringio'

class DismissAndDevicesTest < Minitest::Test
  SEND_RESPONSE = '{"success":true,"notification_id":"pn_123","devices_notified":1,"timestamp":"2026-11-07T09:00:00Z"}'
  DISMISS_RESPONSE = '{"success":true,"notification_id":"pn_123","dismissed_at":"2026-11-07T09:01:00Z","future_field":true}'
  DEVICES_RESPONSE = '{"devices":[{"user_email":"owner@example.com","device_id":"dev_1","device_type":"ios",' \
                     '"is_active":true,"token_status":{"push":true,"start_live_activity":true},"app_version":"1.17.0","device_name":"iPhone",' \
                     '"system_name":"iOS","system_version":"27.0","created_at":"2026-11-01T09:00:00Z",' \
                     '"updated_at":"2026-11-07T09:00:00Z"}],' \
                     '"meta":{"total":1,"limit":100,"offset":0,"has_more":false,"next_offset":null,"include_inactive":false}}'
  METRIC_RESPONSE = '{"metric":{"public_id":"m1","key":"mrr","label":"MRR","format":"currency","currency_code":"USD",' \
                    '"unit":null,"unit_spacing":"none","latest_value":12450,"latest_value_at":"2026-11-07T09:00:00Z",' \
                    '"created_at":"2026-11-07T09:00:00Z","updated_at":"2026-11-07T09:00:00Z"}}'

  # Builds a real client whose shared ApiClient never touches the network.
  def mocked_client(captured)
    activitysmith = ActivitySmith::Client.new(api_key: 'mock-only')
    api_client = activitysmith.notifications.instance_variable_get(:@api).api_client
    api_client.define_singleton_method(:call_api) do |http_method, path, opts = {}|
      request = build_request(http_method, path, opts)
      body = request.options[:body]
      captured << {
        method: http_method,
        path: path,
        params: request.options[:params],
        body: body.nil? || body.empty? ? nil : JSON.parse(body)
      }
      json = case path
             when '/push-notification' then SEND_RESPONSE
             when %r{\A/push-notification/[^/]+/dismiss\z} then DISMISS_RESPONSE
             when '/account/devices' then DEVICES_RESPONSE
             else METRIC_RESPONSE
             end
      response = Struct.new(:body, :headers).new(json, { 'Content-Type' => 'application/json' })
      [deserialize(response, opts[:return_type]), 200, {}]
    end
    activitysmith
  end

  def test_dismiss_posts_and_parses_response
    [:dismiss, :dismiss_push_notification].each do |method|
      captured = []
      activitysmith = mocked_client(captured)
      response = activitysmith.notifications.public_send(method, 'pn_123')

      assert_equal [{ method: :POST, path: '/push-notification/pn_123/dismiss', params: {}, body: nil }], captured
      assert_instance_of OpenapiClient::PushNotificationDismissResponse, response
      assert_equal true, response.success
      assert_equal 'pn_123', response.notification_id
      refute_nil response.dismissed_at
    end
  end

  def test_devices_list_sends_query_and_parses_response
    captured = []
    activitysmith = mocked_client(captured)

    result = activitysmith.devices.list
    activitysmith.devices.list(include_inactive: true, limit: 10)
    activitysmith.devices.list_account_devices(offset: 100)

    assert_equal(
      [
        { method: :GET, path: '/account/devices', params: {}, body: nil },
        { method: :GET, path: '/account/devices', params: { limit: 10, include_inactive: true }, body: nil },
        { method: :GET, path: '/account/devices', params: { offset: 100 }, body: nil }
      ],
      captured
    )
    assert_instance_of OpenapiClient::AccountDeviceListResponse, result
    assert_equal 'dev_1', result.devices.first.device_id
    assert_equal false, result.meta.has_more
  end

  def test_devices_list_encodes_query_string
    ActivitySmith::Client.new(api_key: 'mock-only')
    request = OpenapiClient::ApiClient.new.build_request(:GET, '/account/devices', query_params: { include_inactive: true, limit: 10 })
    url = Typhoeus::EasyFactory.new(request).get.effective_url
    assert_equal 'https://activitysmith.com/api/account/devices?include_inactive=true&limit=10', url
  end

  def test_doc_examples_run_as_written
    captured = []
    activitysmith = mocked_client(captured)
    original_stdout = $stdout
    $stdout = StringIO.new
    begin
      sent = activitysmith.notifications.send({ title: "🙋 Agent needs your input", message: "Approve the database migration?" })
      activitysmith.notifications.dismiss(sent.notification_id)
      result = activitysmith.devices.list
      result.devices.each do |device|
        puts [device.device_name, device.system_name, device.is_active].join(" ")
      end
      activitysmith.devices.list(include_inactive: true)
      activitysmith.metrics.create("mrr", label: "MRR", format: "currency", currency_code: "USD")
      activitysmith.metrics.update("mrr", 12450)
      printed = $stdout.string
    ensure
      $stdout = original_stdout
    end

    assert_equal "iPhone iOS true\n", printed
    assert_equal(
      [
        [:POST, '/push-notification', {}, { 'title' => '🙋 Agent needs your input', 'message' => 'Approve the database migration?' }],
        [:POST, '/push-notification/pn_123/dismiss', {}, nil],
        [:GET, '/account/devices', {}, nil],
        [:GET, '/account/devices', { include_inactive: true }, nil],
        [:PUT, '/metrics/mrr', {}, { 'label' => 'MRR', 'format' => 'currency', 'currency_code' => 'USD' }],
        [:POST, '/metrics/mrr/value', {}, { 'value' => 12450 }]
      ],
      captured.map { |call| call.values_at(:method, :path, :params, :body) }
    )
  end
end
