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

client = ActivitySmith::Client.new(api_key: ENV.fetch("ACTIVITYSMITH_API_KEY"))
```

You can also override the API host:

```ruby
client = ActivitySmith::Client.new(
  api_key: ENV.fetch("ACTIVITYSMITH_API_KEY"),
  base_url: "https://activitysmith.com/api"
)
```

## Usage

### Send a Push Notification

```ruby
response = client.notifications.send(
  {
    title: "Build Failed",
    message: "CI pipeline failed on main branch"
  }
)
```

### Start a Live Activity

```ruby
start = client.live_activities.start(
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
update = client.live_activities.update(
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
finish = client.live_activities.end(
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
  client.notifications.send(
    { title: "Build Failed" }
  )
rescue OpenapiClient::ApiError => e
  puts "Request failed: #{e.code} #{e.message}"
end
```

## API Surface

- `client.notifications`
- `client.live_activities`

## Requirements

- Ruby 3.0+

## License

MIT
