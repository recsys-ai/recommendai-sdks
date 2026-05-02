# RecSys.AI Go SDK

Official Go client for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- Go 1.22+

## Installation

```bash
go get github.com/recsys-ai/recommendai-go
```

## Quick Start

```go
package main

import (
    "fmt"
    "log"
    recommendai "github.com/recsys-ai/recommendai-go"
)

func main() {
    client := recommendai.New("your_api_key")

    // Create a user
    user, err := client.Users.Create("user-123", map[string]interface{}{
        "name": "Alice",
        "age":  28,
    })
    if err != nil { log.Fatal(err) }
    fmt.Println("Created user:", user.UserID)

    // Add an item to the catalogue
    item, err := client.Items.Create("item-456", map[string]interface{}{
        "title": "Inception",
        "genre": "sci-fi",
    })
    if err != nil { log.Fatal(err) }
    fmt.Println("Created item:", item.ItemID)

    // Record an interaction
    _, err = client.Interactions.Create(recommendai.CreateInteractionParams{
        UserID:          "user-123",
        ItemID:          "item-456",
        InteractionType: recommendai.InteractionView,
    })
    if err != nil { log.Fatal(err) }

    // Get personalised recommendations
    recs, err := client.Recommendations.Get("user-123", 10)
    if err != nil { log.Fatal(err) }
    for i, r := range recs {
        fmt.Printf("%d. %s  score=%.4f  %s\n", i+1, r.ItemID, r.Score, r.Reason)
    }
}
```

## Configuration

```go
// Default base URL + timeout
client := recommendai.New("your_api_key")

// Custom base URL
client := recommendai.New("your_api_key",
    recommendai.WithBaseURL("https://api.recsys-ai.com"))

// Custom timeout
client := recommendai.New("your_api_key",
    recommendai.WithTimeout(10 * time.Second))

// Combine options
client := recommendai.New("your_api_key",
    recommendai.WithBaseURL("https://api.recsys-ai.com"),
    recommendai.WithTimeout(15 * time.Second))
```

## API Reference

### Recommendations

```go
// Get recommendations (default limit 10)
recs, err := client.Recommendations.Get("user-123", 10)

// Each Recommendation has:
//   r.ItemID  — the recommended item
//   r.Score   — relevance score (0–1)
//   r.Reason  — human-readable explanation
//   r.Metadata — extra server-side fields
```

### Users

```go
user, err := client.Users.Create("user-123", map[string]interface{}{"name": "Alice"})
user, err := client.Users.Get("user-123")
user, err := client.Users.Update("user-123", map[string]interface{}{"subscription": "premium"})
err        = client.Users.Delete("user-123")
```

### Items

```go
item, err := client.Items.Create("item-456", map[string]interface{}{"title": "Inception"})
item, err  = client.Items.Get("item-456")
item, err  = client.Items.Update("item-456", map[string]interface{}{"remastered": true})
err        = client.Items.Delete("item-456")
```

### Interactions

```go
// Simple interaction
_, err = client.Interactions.Create(recommendai.CreateInteractionParams{
    UserID:          "user-123",
    ItemID:          "item-456",
    InteractionType: recommendai.InteractionView,
})

// With a rating value
rating := 8.5
_, err = client.Interactions.Create(recommendai.CreateInteractionParams{
    UserID:          "user-123",
    ItemID:          "item-456",
    InteractionType: recommendai.InteractionRating,
    Value:           &rating,
})

// Convenience helper for pointer values
_, err = client.Interactions.Create(recommendai.CreateInteractionParams{
    UserID:          "user-123",
    ItemID:          "item-456",
    InteractionType: recommendai.InteractionRating,
    Value:           recommendai.Ptr(8.5),
})
```

Available interaction types: `InteractionView`, `InteractionClick`, `InteractionPurchase`,
`InteractionLike`, `InteractionDislike`, `InteractionRating`, `InteractionCartAdd`,
`InteractionCartRemove`.

## Error Handling

```go
user, err := client.Users.Get("unknown-id")
if err != nil {
    switch {
    case recommendai.IsNotFound(err):
        fmt.Println("User not found:", err)
    case recommendai.IsAuthError(err):
        fmt.Println("Invalid API key")
    case recommendai.IsRateLimit(err):
        fmt.Println("Rate limit exceeded — back off and retry")
    default:
        fmt.Println("Error:", err)
    }
}
```

## Running the Simulation Example

The simulation starts an in-process mock server (port 17893) and exercises the
full SDK — no live API key or service required.

```bash
go run ./examples/simulation.go
```

## Development

```bash
# Run tests
go test ./...

# Build
go build ./...

# Format
gofmt -w .
```

## License

MIT
