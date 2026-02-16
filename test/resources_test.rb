# frozen_string_literal: true

require_relative "test_helper"

class FakePushApi
  attr_reader :calls

  def initialize
    @calls = []
  end

  def send_push_notification(request, opts = {})
    @calls << [:send_push_notification, request, opts]
    { ok: true }
  end

  def send_push_notification_with_http_info(request, opts = {})
    @calls << [:send_push_notification_with_http_info, request, opts]
    [:ok, 200, {}]
  end
end

class FakeLiveApi
  attr_reader :calls

  def initialize
    @calls = []
  end

  def start_live_activity(request, opts = {})
    @calls << [:start_live_activity, request, opts]
    { activity_id: "act-1" }
  end

  def update_live_activity(request, opts = {})
    @calls << [:update_live_activity, request, opts]
    { ok: true }
  end

  def end_live_activity(request, opts = {})
    @calls << [:end_live_activity, request, opts]
    { ok: true }
  end

  def end_live_activity_with_http_info(request, opts = {})
    @calls << [:end_live_activity_with_http_info, request, opts]
    [:ok, 200, {}]
  end
end

class ResourcesTest < Minitest::Test
  def test_notifications_short_and_legacy_methods
    api = FakePushApi.new
    resource = ActivitySmith::Notifications.new(api)
    payload = { title: "Build Failed" }

    assert_equal({ ok: true }, resource.send(payload))
    assert_equal({ ok: true }, resource.send_push_notification(payload))

    assert_equal(
      [
        [:send_push_notification, payload, {}],
        [:send_push_notification, payload, {}]
      ],
      api.calls
    )
  end

  def test_notifications_map_channels_to_target
    api = FakePushApi.new
    resource = ActivitySmith::Notifications.new(api)

    resource.send({ title: "Build Failed", channels: %w[devs ops] })
    resource.send_push_notification({ title: "Build Failed", channels: "devs,ops" })

    expected = { title: "Build Failed", target: { channels: %w[devs ops] } }
    assert_equal(
      [
        [:send_push_notification, expected, {}],
        [:send_push_notification, expected, {}]
      ],
      api.calls
    )
  end

  def test_live_activities_short_and_legacy_methods
    api = FakeLiveApi.new
    resource = ActivitySmith::LiveActivities.new(api)

    start_payload = {
      content_state: {
        title: "Deploy",
        number_of_steps: 4,
        current_step: 1,
        type: "segmented_progress"
      }
    }
    update_payload = {
      activity_id: "act-1",
      content_state: { title: "Deploy", current_step: 2 }
    }
    end_payload = {
      activity_id: "act-1",
      content_state: { title: "Deploy", current_step: 4 }
    }

    resource.start(start_payload)
    resource.update(update_payload)
    resource.end(end_payload)
    resource.start_live_activity(start_payload)
    resource.update_live_activity(update_payload)
    resource.end_live_activity(end_payload)

    assert_equal(
      [
        [:start_live_activity, start_payload, {}],
        [:update_live_activity, update_payload, {}],
        [:end_live_activity, end_payload, {}],
        [:start_live_activity, start_payload, {}],
        [:update_live_activity, update_payload, {}],
        [:end_live_activity, end_payload, {}]
      ],
      api.calls
    )
  end

  def test_live_activities_start_maps_channels_to_target
    api = FakeLiveApi.new
    resource = ActivitySmith::LiveActivities.new(api)

    payload = {
      content_state: {
        title: "Deploy",
        number_of_steps: 4,
        current_step: 1,
        type: "segmented_progress"
      },
      channels: %w[devs ops]
    }

    resource.start(payload)
    resource.start_live_activity(payload)

    expected = {
      content_state: {
        title: "Deploy",
        number_of_steps: 4,
        current_step: 1,
        type: "segmented_progress"
      },
      target: { channels: %w[devs ops] }
    }

    assert_equal(
      [
        [:start_live_activity, expected, {}],
        [:start_live_activity, expected, {}]
      ],
      api.calls
    )
  end

  def test_passthrough_methods
    push_api = FakePushApi.new
    notifications = ActivitySmith::Notifications.new(push_api)
    assert_equal [:ok, 200, {}], notifications.send_push_notification_with_http_info({ title: "x" })

    live_api = FakeLiveApi.new
    live_activities = ActivitySmith::LiveActivities.new(live_api)
    assert_equal [:ok, 200, {}], live_activities.end_live_activity_with_http_info({ activity_id: "act-1" })
  end
end
