# RecSys.AI Rust SDK

Official Rust client for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- Rust 1.75+ (2021 edition)

## Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
recommendai = "1.0.0"
```

## Quick Start

```rust
use std::collections::HashMap;
use serde_json::json;
use recommendai::{RecommendAIClient, InteractionType};

fn main() -> Result<(), recommendai::Error> {
    let client = RecommendAIClient::new("your_api_key")?;

    // Create a user
    let mut props = HashMap::new();
    props.insert("name".to_string(), json!("Alice"));
    props.insert("age".to_string(),  json!(28));
    let user = client.users().create("user-123", props)?;

    // Record an interaction
    client.interactions().create(
        "user-123", "item-456", &InteractionType::View, None, None
    )?;

    // Get recommendations
    let recs = client.recommendations().get("user-123", 10)?;
    for r in &recs {
        println!("{}: {:.4}  {}", r.item_id, r.score, r.reason);
    }
    Ok(())
}
```

## Configuration

```rust
use std::time::Duration;
use recommendai::{RecommendAIClient, ClientConfig};

let client = RecommendAIClient::with_config("your_api_key", ClientConfig {
    base_url: "https://api.recsys-ai.com".to_string(),
    timeout:  Duration::from_secs(30),
})?;
```

## API Reference

### Recommendations

```rust
let recs = client.recommendations().get("user-123", 10)?;
// Vec<Recommendation> — item_id, score, reason, metadata
```

### Users

```rust
client.users().create("user-123", props)?;
client.users().get("user-123")?;
client.users().update("user-123", new_props)?;
client.users().delete("user-123")?;
```

### Items

```rust
client.items().create("item-456", props)?;
client.items().get("item-456")?;
client.items().update("item-456", new_props)?;
client.items().delete("item-456")?;
```

### Interactions

```rust
use recommendai::InteractionType;

client.interactions().create(
    "user-123", "item-456", &InteractionType::View, None, None
)?;

// Rating with value
client.interactions().create(
    "user-123", "item-456", &InteractionType::Rating, Some(8.5), None
)?;
```

## Error Handling

```rust
use recommendai::Error;

match client.users().get("ghost") {
    Ok(user) => println!("Found: {}", user.user_id),
    Err(Error::NotFound(msg)) => println!("Not found: {msg}"),
    Err(Error::Authentication(msg)) => println!("Auth error: {msg}"),
    Err(Error::RateLimit(msg)) => println!("Rate limited: {msg}"),
    Err(e) => println!("Error: {e}"),
}
```

## Running the Simulation Example

The simulation starts a `tiny_http` mock server on port 17897 in a background thread.
No live API key or service is required.

```bash
cargo run --example simulation
```

## License

MIT
