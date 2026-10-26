# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class MetricsCreateTest < Minitest::Test
  METRIC_RESPONSE = '{"metric":{"public_id":"m1","key":"mrr","label":"MRR","format":"currency","currency_code":"USD",' \
                    '"unit":null,"unit_spacing":"none","latest_value":null,"latest_value_at":null,' \
                    '"created_at":"2026-10-26T09:00:00Z","updated_at":"2026-10-26T09:00:00Z"}}'

  def metrics_with_capture(captured)
    ActivitySmith::Client.new(api_key: 'mock-only')
    api_client = OpenapiClient::ApiClient.new
    api_client.define_singleton_method(:call_api) do |http_method, path, opts = {}|
      request = build_request(http_method, path, opts)
      body = request.options[:body]
      captured << [http_method, path, body.nil? || body.empty? ? nil : JSON.parse(body)]
      response = Struct.new(:body, :headers).new(METRIC_RESPONSE, { 'Content-Type' => 'application/json' })
      [deserialize(response, opts[:return_type]), 201, {}]
    end
    ActivitySmith::Metrics.new(OpenapiClient::MetricsApi.new(api_client))
  end

  def test_create_serializes_definition_forms
    expected = { 'label' => 'MRR', 'format' => 'currency', 'currency_code' => 'USD' }
    captured = []
    metrics = metrics_with_capture(captured)

    response = metrics.create('mrr', label: 'MRR', format: 'currency', currency_code: 'USD')
    metrics.create('mrr', { label: 'MRR', format: 'currency', currency_code: 'USD' })
    metrics.upsert_metric('mrr', metric_upsert_request: { label: 'MRR', format: 'currency', currency_code: 'USD' })

    assert_equal [[:PUT, '/metrics/mrr', expected]] * 3, captured
    assert_equal 'USD', response.metric.currency_code
    assert_nil response.metric.unit
  end

  def test_create_merges_keywords_and_sends_no_body_for_defaults
    captured = []
    metrics = metrics_with_capture(captured)

    metrics.create('latency', { format: 'unit', unit: 'ms' }, unit_spacing: 'space')
    metrics.create('deploy.success_rate')

    assert_equal [:PUT, '/metrics/latency', { 'format' => 'unit', 'unit' => 'ms', 'unit_spacing' => 'space' }], captured[0]
    assert_equal [:PUT, '/metrics/deploy.success_rate', nil], captured[1]
  end
end
