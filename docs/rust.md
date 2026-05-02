# Rust SDK

## Installation

Add to `Cargo.toml`:

```toml
[dependencies]
recommendai = "1"
```

Requires Rust 1.70+.

## Quick Start

```rust
use recommendai::RecommendAIClient;
use serde_json::json;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = RecommendAIClient::new("your_api_key");

    // Health check
    let alive = client.ping();
    println!("{}", alive); // true

    // Similar items
    let similar = client.recommendations().similar("item-123", 10)?;
    for r in &similar {
        println!("{} {}", r.item_id, r.score);
    }

    // Popular items
    let popular = client.recommendations().popular(5, Some("books"))?;

    // Bulk upsert
    client.items().upsert(vec![
        json!({"item_id": "item-1", "properties": {"title": "Book A"}}),
    ])?;

    Ok(())
}
```

## Configuration

```rust
use recommendai::{RecommendAIClient, ClientConfig};
use std::time::Duration;

let client = RecommendAIClient::with_config(
    "your_api_key",
    ClientConfig {
        base_url: "https://api.recsys.ai".to_string(),
        timeout: Duration::from_secs(30),
    },
);
```

## Error Handling

```rust
use recommendai::errors::Error;

match client.recommendations().similar("item-123", 10) {
    Ok(recs) => { /* ... */ }
    Err(Error::Authentication(msg)) => eprintln!("Auth error: {}", msg),
    Err(Error::NotFound(msg))       => eprintln!("Not found: {}", msg),
    Err(Error::RateLimit(msg))      => eprintln!("Rate limited: {}", msg),
    Err(e)                          => return Err(e.into()),
}
```

## API Reference

### `RecommendAIClient`

| Method | Returns | Description |
|---|---|---|
| `ping()` | `bool` | `true` if API is healthy |

### `recommendations()`

| Method | Returns |
|---|---|
| `similar(item_id, limit)` | `Result<Vec<Recommendation>, Error>` |
| `popular(limit, category)` | `Result<Vec<Recommendation>, Error>` |

### `items()`

| Method | Returns |
|---|---|
| `upsert(items)` | `Result<Vec<Item>, Error>` |
