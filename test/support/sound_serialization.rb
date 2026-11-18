# frozen_string_literal: true

require_relative '../test_helper'
require 'json'

class SoundSerializationTest < Minitest::Test
  CONTENT_STATE = { title: 'Deploy', type: 'segmented_progress', number_of_steps: 3, current_step: 1 }.freeze

  # Builds a real client whose shared ApiClient never touches the network.
  def mocked_client(captured)
    activitysmith = ActivitySmith::Client.new(api_key: 'mock-only')
    api_client = activitysmith.notifications.instance_variable_get(:@api).api_client
    api_client.define_singleton_method(:call_api) do |http_method, path, opts = {}|
      request = build_request(http_method, path, opts)
      body = request.options[:body]
      captured << [http_method, path, body.nil? || body.empty? ? nil : JSON.parse(body)]
      [nil, 200, {}]
    end
    activitysmith
  end

  def last_body(captured)
    captured.last[2]
  end

  def test_push_notification_send_serializes_sound
    captured = []
    notifications = mocked_client(captured).notifications

    notifications.send(title: 'Build passed', sound: 'chime')
    assert_equal [:POST, '/push-notification', { 'title' => 'Build passed', 'sound' => 'chime' }], captured.last

    notifications.send({ title: 'Build passed', sound: 'none' }, tags: ['ci'])
    assert_equal({ 'title' => 'Build passed', 'tags' => ['ci'], 'sound' => 'none' }, last_body(captured))

    notifications.send_push_notification(OpenapiClient::PushNotificationRequest.new(title: 'Build passed', sound: 'default'))
    assert_equal({ 'title' => 'Build passed', 'sound' => 'default' }, last_body(captured))

    notifications.send(title: 'Build passed')
    refute last_body(captured).key?('sound')
  end

  def test_live_activity_start_update_end_serialize_sound
    captured = []
    live_activities = mocked_client(captured).live_activities

    live_activities.start(content_state: CONTENT_STATE, sound: 'bell', channels: ['ops'])
    assert_equal :POST, captured.last[0]
    assert_equal '/live-activity/start', captured.last[1]
    assert_equal 'bell', last_body(captured)['sound']
    assert_equal({ 'channels' => ['ops'] }, last_body(captured)['target'])

    live_activities.start_live_activity({ content_state: CONTENT_STATE, sound: 'none' })
    assert_equal 'none', last_body(captured)['sound']

    live_activities.update(activity_id: 'la_1', content_state: { title: 'Deploy', current_step: 2 }, sound: 'ding')
    assert_equal [:POST, '/live-activity/update'], captured.last[0, 2]
    assert_equal 'ding', last_body(captured)['sound']

    live_activities.update_live_activity({ activity_id: 'la_1', content_state: { title: 'Deploy', current_step: 2 }, sound: 'default' })
    assert_equal 'default', last_body(captured)['sound']

    live_activities.update(activity_id: 'la_1', content_state: { title: 'Deploy', current_step: 2 })
    refute last_body(captured).key?('sound')

    live_activities.end(activity_id: 'la_1', content_state: { title: 'Deploy', current_step: 3 }, sound: 'flourish')
    assert_equal [:POST, '/live-activity/end'], captured.last[0, 2]
    assert_equal 'flourish', last_body(captured)['sound']

    live_activities.end_live_activity(
      OpenapiClient::LiveActivityEndRequest.new(activity_id: 'la_1', content_state: { title: 'Deploy', current_step: 3 }, sound: 'pop')
    )
    assert_equal 'pop', last_body(captured)['sound']
  end

  def test_live_activity_stream_put_and_delete_serialize_sound
    captured = []
    live_activities = mocked_client(captured).live_activities

    live_activities.stream('deploy-main', content_state: CONTENT_STATE, sound: 'signal')
    assert_equal [:PUT, '/live-activity/stream/deploy-main'], captured.last[0, 2]
    assert_equal 'signal', last_body(captured)['sound']

    live_activities.reconcile_live_activity_stream('deploy-main', { content_state: CONTENT_STATE, sound: 'none' })
    assert_equal 'none', last_body(captured)['sound']

    live_activities.end_stream('deploy-main', content_state: { title: 'Deploy', current_step: 3 }, sound: 'crest')
    assert_equal [:DELETE, '/live-activity/stream/deploy-main'], captured.last[0, 2]
    assert_equal 'crest', last_body(captured)['sound']

    live_activities.end_live_activity_stream('deploy-main', { sound: 'default' })
    assert_equal [:DELETE, '/live-activity/stream/deploy-main', { 'sound' => 'default' }], captured.last
  end
end
