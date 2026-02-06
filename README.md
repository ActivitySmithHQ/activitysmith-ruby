# ActivitySmith Ruby SDK

The ActivitySmith Ruby SDK provides convenient access to the ActivitySmith API from Ruby applications.

## Documentation

See [API reference](https://activitysmith.com/docs/api-reference/introduction).

## Installation

```sh
gem install activitysmith
```

## Usage

```ruby
require "activitysmith"

client = ActivitySmith::Client.new(api_key: ENV.fetch("ACTIVITYSMITH_API_KEY"))

client.notifications.send_push_notification(
  push_notification_request: {
    title: "Build Failed",
    message: "CI pipeline failed on main branch"
  }
)

start = client.live_activities.start_live_activity(
  live_activity_start_request: {
    content_state: {
      title: "Deploy",
      number_of_steps: 4,
      current_step: 1,
      type: "segmented_progress"
    }
  }
)

activity_id = start.activity_id
```

## API Surface

- `client.notifications`
- `client.live_activities`

## Requirements

- Ruby 3.0+

## License

MIT
