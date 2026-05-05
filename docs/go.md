# Go SDK

## Installation

```bash
go get github.com/recsys-ai/recommendai-sdks/go/recommendai
```

Requires Go 1.21+.

## Quick Start

```go
package main

import (
    "context"
    "fmt"
    "github.com/recsys-ai/recommendai-sdks/go/recommendai"
)

func main() {
    client := recommendai.NewClient("your_api_key")
    ctx := context.Background()

    // Health check
    ok, _ := client.Ping(ctx)
    fmt.Println(ok) // true

    // Similar items
    recs, err := client.Recommendations.Similar(ctx, "item-123", 10)
    if err != nil {
        panic(err)
    }
    for _, r := range recs {
        fmt.Println(r.ItemID, r.Score)
    }

    // Popular items
    popular, _ := client.Recommendations.Popular(ctx, 5, "books")

    // Bulk upsert
    items, _ := client.Items.Upsert(ctx, []map[string]any{
        {"item_id": "item-1", "properties": map[string]any{"title": "Book A"}},
    })
    _ = popular
    _ = items
}
```

## Configuration

```go
client := recommendai.NewClientWithConfig("your_api_key", recommendai.ClientConfig{
    BaseURL: "https://api.recsys.ai",
    Timeout: 30 * time.Second,
})
```

## Error Handling

```go
import "github.com/recsys-ai/recommendai-sdks/go/recommendai"

recs, err := client.Recommendations.Similar(ctx, "item-123", 10)
if err != nil {
    switch {
    case errors.As(err, &recommendai.AuthError{}):
        fmt.Println("Invalid API key")
    case errors.As(err, &recommendai.NotFoundError{}):
        fmt.Println("Item not found")
    case errors.As(err, &recommendai.RateLimitError{}):
        fmt.Println("Rate limit exceeded")
    default:
        panic(err)
    }
}
```

## API Reference

### `Client`

| Field | Type | Description |
|---|---|---|
| `Recommendations` | `*RecommendationsResource` | Recommendation methods |
| `Items` | `*ItemsResource` | Item management methods |

| Method | Signature | Description |
|---|---|---|
| `Ping` | `Ping(ctx context.Context) (bool, error)` | Health check |

### `RecommendationsResource`

| Method | Signature |
|---|---|
| `Similar` | `Similar(ctx, itemID string, limit int) ([]Recommendation, error)` |
| `Popular` | `Popular(ctx, limit int, category string) ([]Recommendation, error)` |

### `ItemsResource`

| Method | Signature |
|---|---|
| `Upsert` | `Upsert(ctx, items []map[string]any) ([]Item, error)` |
