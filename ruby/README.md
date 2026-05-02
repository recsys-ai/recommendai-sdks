# RecSys.AI Ruby SDK

Official Ruby client for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- Ruby 3.0+

## Installation

Add to your `Gemfile`:

```ruby
gem "recommendai"
```

Or install directly:

```bash
gem install recommendai
```

## Quick Start

```ruby
require "recommendai"

client = RecommendAI::Client.new(api_key: "your_api_key")

# Create a user
user = client.users.create("user-123", properties: { "name" => "Alice", "age" => 28 })

# Add an item to the catalogue
item = client.items.create("item-456", properties: { "title" => "Inception", "genre" => "sci-fi" })

# Record an interaction
client.interactions.create(user_id: "user-123", item_id: "item-456", interaction_type: "view")

# Get personalised recommendations
recs = client.recommendations.get("user-123", limit: 10)
recs.each { |r| puts "#{r.item_id}  score=#{r.score}  #{r.reason}" }
```

## Configuration

```ruby
client = RecommendAI::Client.new(
  api_key:  "your_api_key",
  base_url: "https://api.recsys-ai.com",   # default
  timeout:  30                              # seconds, default
)
```

## API Reference

### Recommendations

```ruby
recs = client.recommendations.get("user-123", limit: 10)
# recs is an Array of RecommendAI::Recommendation Structs
# r.item_id, r.score, r.reason, r.metadata
```

### Users

```ruby
user = client.users.create("user-123", properties: { ... })
user = client.users.get("user-123")
user = client.users.update("user-123", properties: { "subscription" => "premium" })
client.users.delete("user-123")
```

### Items

```ruby
item = client.items.create("item-456", properties: { ... })
item = client.items.get("item-456")
item = client.items.update("item-456", properties: { "remastered" => true })
client.items.delete("item-456")
```

### Interactions

```ruby
# Simple
client.interactions.create(user_id: "u", item_id: "i", interaction_type: "view")

# With rating
client.interactions.create(user_id: "u", item_id: "i", interaction_type: "rating", value: 8.5)
```

Available interaction types: `view`, `click`, `purchase`, `like`, `dislike`, `rating`,
`cart_add`, `cart_remove`.

## Error Handling

```ruby
begin
  client.users.get("ghost")
rescue RecommendAI::NotFoundError => e
  puts "Not found: #{e.message}"
rescue RecommendAI::AuthenticationError => e
  puts "Auth error: #{e.message}"
rescue RecommendAI::RateLimitError => e
  puts "Rate limited: #{e.message}"
rescue RecommendAI::Error => e
  puts "API error (#{e.status_code}): #{e.message}"
end
```

## Running the Simulation Example

The simulation starts an in-process WEBrick mock server on port 17895
and exercises the full SDK — no live API key or service required.

```bash
ruby examples/simulation.rb
```

## License

MIT
