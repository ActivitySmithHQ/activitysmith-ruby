# ActivitySmith Ruby SDK

The ActivitySmith Ruby SDK provides convenient access to the ActivitySmith API from Ruby applications.

## Documentation

See [API reference](https://activitysmith.com/docs/api-reference/introduction).

## Installation

```sh
gem install activitysmith
```

## Setup

```ruby
require "activitysmith"

activitysmith = ActivitySmith::Client.new(api_key: ENV.fetch("ACTIVITYSMITH_API_KEY"))
```

## Usage

### Send a Push Notification

<p align="center">
  <img src="https://cdn.activitysmith.com/features/new-subscription-push-notification.png" alt="Push notification example" width="680" />
</p>

```ruby
response = activitysmith.notifications.send(
  {
    title: "New subscription 💸",
    message: "Customer upgraded to Pro plan"
  }
)

puts response.success
puts response.devices_notified
```

### Start a Live Activity

<p align="center">
  <img src="https://cdn.activitysmith.com/features/start-live-activity.png" alt="Start live activity example" width="680" />
</p>

```ruby
start = activitysmith.live_activities.start(
  {
    content_state: {
      title: "Nightly database backup",
      subtitle: "create snapshot",
      number_of_steps: 3,
      current_step: 1,
      type: "segmented_progress",
      color: "yellow"
    },
    channels: ["devs", "ops"] # Optional
  }
)

activity_id = start.activity_id
```

For a simple progress bar, send `type: "progress"` with `percentage` or `value` plus `upper_limit`.

```ruby
start = activitysmith.live_activities.start(
  {
    content_state: {
      title: "Model fine-tuning",
      subtitle: "uploading shards",
      type: "progress",
      percentage: 67,
      color: "purple"
    }
  }
)
```

### Update a Live Activity

<p align="center">
  <img src="https://cdn.activitysmith.com/features/update-live-activity.png" alt="Update live activity example" width="680" />
</p>

```ruby
update = activitysmith.live_activities.update(
  {
    activity_id: activity_id,
    content_state: {
      title: "Nightly database backup",
      subtitle: "upload archive",
      current_step: 2
    }
  }
)

puts update.devices_notified
```

Progress update example:

```ruby
activitysmith.live_activities.update(
  {
    activity_id: activity_id,
    content_state: {
      title: "Model fine-tuning",
      subtitle: "processing batches",
      type: "progress",
      value: 241,
      upper_limit: 360
    }
  }
)
```

### End a Live Activity

<p align="center">
  <img src="https://cdn.activitysmith.com/features/end-live-activity.png" alt="End live activity example" width="680" />
</p>

```ruby
finish = activitysmith.live_activities.end(
  {
    activity_id: activity_id,
    content_state: {
      title: "Nightly database backup",
      subtitle: "verify restore",
      current_step: 3,
      auto_dismiss_minutes: 2
    }
  }
)

puts finish.success
```

## Channels

Channels are used to target specific team members or devices. Can be used for both push notifications and live activities.

```ruby
response = activitysmith.notifications.send(
  {
    title: "New subscription 💸",
    message: "Customer upgraded to Pro plan",
    channels: ["sales", "customer-success"] # Optional
  }
)
```

## Push Notification Redirection and Actions

Push notification redirection and actions are optional and can be used to redirect the user to a specific URL when they tap the notification or to trigger a specific action when they long-press the notification.
Webhooks are executed by ActivitySmith backend.

```ruby
response = activitysmith.notifications.send(
  {
    title: "New subscription 💸",
    message: "Customer upgraded to Pro plan",
    redirection: "https://crm.example.com/customers/cus_9f3a1d", # Optional
    actions: [ # Optional (max 4)
      {
        title: "Open CRM Profile",
        type: "open_url",
        url: "https://crm.example.com/customers/cus_9f3a1d"
      },
      {
        title: "Start Onboarding Workflow",
        type: "webhook",
        url: "https://hooks.example.com/activitysmith/onboarding/start",
        method: "POST",
        body: {
          customer_id: "cus_9f3a1d",
          plan: "pro"
        }
      }
    ]
  }
)
```

## Error Handling

```ruby
begin
  activitysmith.notifications.send(
    { title: "New subscription 💸" }
  )
rescue OpenapiClient::ApiError => err
  puts "Request failed: #{err.code} #{err.message}"
end
```

## Requirements

- Ruby 3.0+

## License

MIT
