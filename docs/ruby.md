# Ruby SDK

## Installation

```bash
gem install recommendai
```

Or add to your `Gemfile`:

```ruby
gem 'recommendai', '~> 1.0'
```

Requires Ruby 3.0+.

## Quick Start

```ruby
require 'recommendai'

client = RecommendAI::Client.new(api_key: 'your_api_key')

# Health check
puts client.ping # true

# Similar items
similar = client.recommendations.similar('item-123', limit: 10)
similar.each { |r| puts "#{r.item_id}  #{r.score}" }

# Popular items
popular = client.recommendations.popular(limit: 5, category: 'books')

# Bulk upsert
client.items.upsert([
  { item_id: 'item-1', properties: { title: 'Book A' } },
])
```

## Configuration

```ruby
client = RecommendAI::Client.new(
  api_key: 'your_api_key',
  base_url: 'https://api.recsys.ai',
  timeout: 30,
)
```

## Error Handling

```ruby
require 'recommendai/errors'

begin
  client.recommendations.similar('item-123')
rescue RecommendAI::AuthenticationError => e
  warn "Authentication failed: #{e.message}"
rescue RecommendAI::NotFoundError => e
  warn "Not found: #{e.message}"
rescue RecommendAI::RateLimitError => e
  warn "Rate limited: #{e.message}"
end
```

## API Reference

### `RecommendAI::Client`

| Method | Returns | Description |
|---|---|---|
| `ping` | `Boolean` | `true` if API is healthy |

### `recommendations`

| Method | Returns |
|---|---|
| `similar(item_id, limit:)` | `Array<Recommendation>` |
| `popular(limit:, category:)` | `Array<Recommendation>` |

### `items`

| Method | Returns |
|---|---|
| `upsert(items)` | `Array<Item>` |
