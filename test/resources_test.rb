# frozen_string_literal: true

require_relative "test_helper"
require File.expand_path("../generated/activitysmith_openapi/models/live_activity_action", __dir__)
require File.expand_path("../generated/activitysmith_openapi/models/live_activity_action_type", __dir__)
require File.expand_path("../generated/activitysmith_openapi/models/push_notification_action", __dir__)
require File.expand_path("../generated/activitysmith_openapi/models/push_notification_action_type", __dir__)
require File.expand_path("../generated/activitysmith_openapi/models/push_notification_request", __dir__)

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

  def reconcile_live_activity_stream(stream_key, request, opts = {})
    @calls << [:reconcile_live_activity_stream, stream_key, request, opts]
    { success: true, operation: "started", stream_key: stream_key }
  end

  def end_live_activity_stream(stream_key, opts = {})
    @calls << [:end_live_activity_stream, stream_key, opts]
    { success: true, operation: "ended", stream_key: stream_key }
  end
end

class FakeMetricsApi
  attr_reader :calls

  def initialize
    @calls = []
  end

  def update_metric_value(key, request, opts = {})
    @calls << [:update_metric_value, key, request, opts]
    { metric: { key: key } }
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

  def test_notifications_preserve_media_and_redirection
    api = FakePushApi.new
    resource = ActivitySmith::Notifications.new(api)

    payload = {
      title: "Voice Over Generated",
      media: "https://cdn.activitysmith.com/voice_over.mp3",
      redirection: "https://studio.acme.com/voice-overs/482/review"
    }

    resource.send(payload)
    resource.send(
      title: "Run Shortcut",
      redirection: "shortcuts://run-shortcut?name=Jarvis"
    )

    assert_equal(
      [
        [:send_push_notification, payload, {}],
        [
          :send_push_notification,
          {
            title: "Run Shortcut",
            redirection: "shortcuts://run-shortcut?name=Jarvis"
          },
          {}
        ]
      ],
      api.calls
    )
  end

  def test_notifications_reject_media_and_actions
    api = FakePushApi.new
    resource = ActivitySmith::Notifications.new(api)

    error = assert_raises(ArgumentError) do
      resource.send(
        {
          title: "Voice Over Generated",
          media: "https://cdn.activitysmith.com/voice_over.mp3",
          actions: [{ title: "Open", type: "open_url", url: "https://example.com" }]
        }
      )
    end

    assert_equal "ActivitySmith: media cannot be combined with actions", error.message
    assert_empty api.calls
  end

  def test_notifications_preserve_shortcuts_open_url_actions
    api = FakePushApi.new
    resource = ActivitySmith::Notifications.new(api)

    payload = {
      title: "Task finished",
      actions: [
        {
          title: "Run Shortcut",
          type: "open_url",
          url: "shortcuts://run-shortcut?name=Jarvis"
        }
      ]
    }

    resource.send(payload)

    assert_equal(
      [
        [:send_push_notification, payload, {}]
      ],
      api.calls
    )
  end

  def test_generated_push_notification_open_url_allows_shortcuts
    action = OpenapiClient::PushNotificationAction.new(
      title: "Chat",
      type: OpenapiClient::PushNotificationActionType::OPEN_URL,
      url: "shortcuts://run-shortcut?name=JARVIS"
    )

    assert action.valid?
  end

  def test_generated_push_notification_redirection_allows_shortcuts
    request = OpenapiClient::PushNotificationRequest.new(
      title: "Task finished",
      redirection: "shortcuts://run-shortcut?name=Jarvis"
    )

    assert request.valid?
  end

  def test_generated_live_activity_open_url_allows_shortcuts
    action = OpenapiClient::LiveActivityAction.new(
      title: "Chat",
      type: OpenapiClient::LiveActivityActionType::OPEN_URL,
      url: "shortcuts://run-shortcut?name=JARVIS"
    )

    assert action.valid?
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

  def test_live_activities_support_progress_payloads
    api = FakeLiveApi.new
    resource = ActivitySmith::LiveActivities.new(api)

    payload = {
      content_state: {
        title: "Render export",
        subtitle: "encoding frames",
        type: "progress",
        percentage: 67,
        color: "purple"
      }
    }

    resource.start(payload)

    assert_equal(
      [
        [:start_live_activity, payload, {}]
      ],
      api.calls
    )
  end

  def test_live_activities_support_stats_payloads
    api = FakeLiveApi.new
    resource = ActivitySmith::LiveActivities.new(api)

    payload = {
      content_state: {
        title: "Sales",
        subtitle: "last hour",
        type: ActivitySmith::LiveActivities::TYPE_STATS,
        metrics: [
          { label: "Revenue", value: "$2430", color: "blue" },
          { label: "Orders", value: "37", color: "green" },
          { label: "Conversion", value: "4.8%", color: "magenta" }
        ]
      }
    }

    resource.start(payload)

    assert_equal(
      [
        [:start_live_activity, payload, {}]
      ],
      api.calls
    )
  end

  def test_live_activities_support_alert_helpers
    api = FakeLiveApi.new
    resource = ActivitySmith::LiveActivities.new(api)

    state = ActivitySmith::LiveActivities.content_state(
      title: "Reactivation",
      type: ActivitySmith::LiveActivities::TYPE_ALERT,
      message: "Lumen came back after 2 weeks",
      icon: ActivitySmith::LiveActivities.alert_icon("cloud.sun", color: "yellow"),
      badge: ActivitySmith::LiveActivities.alert_badge("Customer", color: "magenta"),
      color: "red"
    )
    payload = { content_state: state }

    resource.stream("customer-ops", payload)

    assert_equal(
      [
        [
          :reconcile_live_activity_stream,
          "customer-ops",
          {
            content_state: {
              title: "Reactivation",
              type: ActivitySmith::LiveActivities::TYPE_ALERT,
              message: "Lumen came back after 2 weeks",
              color: "red",
              icon: { symbol: "cloud.sun", color: "yellow" },
              badge: { title: "Customer", color: "magenta" }
            }
          },
          {}
        ]
      ],
      api.calls
    )
  end

  def test_live_activities_support_icon_and_badge_on_non_alert_types
    api = FakeLiveApi.new
    resource = ActivitySmith::LiveActivities.new(api)

    resource.stream(
      "prod-web-1",
      content_state: ActivitySmith::LiveActivities.content_state(
        title: "Server Health",
        subtitle: "prod-web-1",
        type: ActivitySmith::LiveActivities::TYPE_METRICS,
        icon: ActivitySmith::LiveActivities.alert_icon("server.rack", color: "blue"),
        metrics: [{ label: "CPU", value: 18, unit: "%" }]
      )
    )
    resource.stream(
      "nightly-database-backup",
      content_state: ActivitySmith::LiveActivities.content_state(
        title: "Nightly Database Backup",
        subtitle: "verify restore",
        type: ActivitySmith::LiveActivities::TYPE_PROGRESS,
        badge: ActivitySmith::LiveActivities.alert_badge("S3", color: "cyan"),
        percentage: 62
      )
    )

    assert_equal(
      [
        [
          :reconcile_live_activity_stream,
          "prod-web-1",
          {
            content_state: {
              title: "Server Health",
              subtitle: "prod-web-1",
              type: ActivitySmith::LiveActivities::TYPE_METRICS,
              icon: { symbol: "server.rack", color: "blue" },
              metrics: [{ label: "CPU", value: 18, unit: "%" }]
            }
          },
          {}
        ],
        [
          :reconcile_live_activity_stream,
          "nightly-database-backup",
          {
            content_state: {
              title: "Nightly Database Backup",
              subtitle: "verify restore",
              type: ActivitySmith::LiveActivities::TYPE_PROGRESS,
              badge: { title: "S3", color: "cyan" },
              percentage: 62
            }
          },
          {}
        ]
      ],
      api.calls
    )
  end

  def test_live_activities_stream_short_and_legacy_methods
    api = FakeLiveApi.new
    resource = ActivitySmith::LiveActivities.new(api)

    stream_payload = {
      content_state: {
        title: "Server Health",
        subtitle: "prod-web-1",
        type: "metrics",
        metrics: [
          { label: "CPU", value: 9, unit: "%" },
          { label: "MEM", value: 45, unit: "%" }
        ]
      },
      channels: ["ops"]
    }
    end_payload = {
      content_state: {
        title: "Server Health",
        subtitle: "prod-web-1",
        type: "metrics",
        metrics: [
          { label: "CPU", value: 7, unit: "%" },
          { label: "MEM", value: 38, unit: "%" }
        ]
      }
    }

    resource.stream("prod-web-1", stream_payload)
    resource.reconcile_live_activity_stream("prod-web-1", stream_payload)
    resource.end_stream("prod-web-1", end_payload)
    resource.end_live_activity_stream("prod-web-1", end_payload)

    expected_stream_payload = {
      content_state: stream_payload[:content_state],
      target: { channels: ["ops"] }
    }

    assert_equal(
      [
        [:reconcile_live_activity_stream, "prod-web-1", expected_stream_payload, {}],
        [:reconcile_live_activity_stream, "prod-web-1", expected_stream_payload, {}],
        [
          :end_live_activity_stream,
          "prod-web-1",
          { live_activity_stream_delete_request: end_payload }
        ],
        [
          :end_live_activity_stream,
          "prod-web-1",
          { live_activity_stream_delete_request: end_payload }
        ]
      ],
      api.calls
    )
  end

  def test_metrics_short_and_legacy_methods
    api = FakeMetricsApi.new
    resource = ActivitySmith::Metrics.new(api)

    resource.update("deploy.success_rate", 99.9, timestamp: "2026-05-03T12:30:00.000Z")
    resource.update("prod.status", { value: "healthy" })
    resource.update_metric_value("deploy.success_rate", { value: 42 })

    assert_equal(
      [
        [
          :update_metric_value,
          "deploy.success_rate",
          { value: 99.9, timestamp: "2026-05-03T12:30:00.000Z" },
          {}
        ],
        [:update_metric_value, "prod.status", { value: "healthy" }, {}],
        [:update_metric_value, "deploy.success_rate", { value: 42 }, {}]
      ],
      api.calls
    )
  end

  def test_live_activities_pass_action_payloads_through
    api = FakeLiveApi.new
    resource = ActivitySmith::LiveActivities.new(api)

    start_payload = {
      content_state: {
        title: "Deploying payments-api",
        subtitle: "Running database migrations",
        number_of_steps: 5,
        current_step: 3,
        type: "segmented_progress"
      },
      action: {
        title: "Open Workflow",
        type: "open_url",
        url: "shortcuts://run-shortcut?name=Deploy%20Status"
      }
    }

    update_payload = {
      activity_id: "act-1",
      content_state: {
        title: "Reindexing product search",
        subtitle: "Shard 7 of 12",
        number_of_steps: 12,
        current_step: 7
      },
      action: {
        title: "Pause Reindex",
        type: "webhook",
        url: "https://ops.example.com/hooks/search/reindex/pause",
        method: "POST",
        body: {
          job_id: "reindex-2026-03-19"
        }
      }
    }

    end_payload = {
      activity_id: "act-1",
      content_state: {
        title: "Deploying payments-api",
        subtitle: "Production rollout complete",
        number_of_steps: 5,
        current_step: 5
      },
      action: {
        title: "Open Workflow",
        type: "open_url",
        url: "shortcuts://run-shortcut?name=Deploy%20Status"
      }
    }

    resource.start(start_payload)
    resource.update(update_payload)
    resource.end(end_payload)

    assert_equal(
      [
        [:start_live_activity, start_payload, {}],
        [:update_live_activity, update_payload, {}],
        [:end_live_activity, end_payload, {}]
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
