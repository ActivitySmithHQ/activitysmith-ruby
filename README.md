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

```ruby
response = activitysmith.notifications.send(
  {
    title: "Build Failed",
    message: "CI pipeline failed on main branch"
  }
)
```

### Start a Live Activity

```ruby
start = activitysmith.live_activities.start(
  {
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

### Update a Live Activity

```ruby
update = activitysmith.live_activities.update(
  {
    activity_id: activity_id,
    content_state: {
      title: "Deploy",
      current_step: 3
    }
  }
)
```

### End a Live Activity

```ruby
finish = activitysmith.live_activities.end(
  {
    activity_id: activity_id,
    content_state: {
      title: "Deploy Complete",
      current_step: 4,
      auto_dismiss_minutes: 3
    }
  }
)
```

## Error Handling

```ruby
begin
  activitysmith.notifications.send(
    { title: "Build Failed" }
  )
rescue OpenapiClient::ApiError => e
  puts "Request failed: #{e.code} #{e.message}"
end
```

## API Surface

- `activitysmith.notifications`
- `activitysmith.live_activities`

## Requirements

- Ruby 3.0+

## License

MIT
