# Swift SDK

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/recsys-ai/recommendai-sdk",
        from: "1.0.0"
    ),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "RecommendAI", package: "recommendai-sdk")
        ]
    ),
]
```

Or in Xcode: **File → Add Package Dependencies** and enter the repository URL.

Requires Swift 5.9+ / iOS 16+ / macOS 13+.

## Quick Start

```swift
import RecommendAI

let client = RecommendAIClient(apiKey: "your_api_key")

// Health check
let alive = await client.ping()
print(alive) // true

// Similar items
let similar = try await client.recommendations.similar(itemId: "item-123", limit: 10)
for r in similar {
    print("\(r.itemId)  \(r.score)")
}

// Popular items
let popular = try await client.recommendations.popular(limit: 5, category: "books")

// Bulk upsert
let items = try await client.items.upsert(items: [
    ["item_id": "item-1", "properties": ["title": "Book A"]],
])
```

## Configuration

```swift
let client = RecommendAIClient(
    apiKey: "your_api_key",
    config: ClientConfig(
        baseURL: "https://api.recsys.ai",
        timeout: 30
    )
)
```

## Error Handling

```swift
import RecommendAI

do {
    let recs = try await client.recommendations.similar(itemId: "item-123", limit: 10)
} catch RecommendAIError.authentication(let msg) {
    print("Invalid API key: \(msg)")
} catch RecommendAIError.notFound(let msg) {
    print("Not found: \(msg)")
} catch RecommendAIError.rateLimit(let msg) {
    print("Rate limited: \(msg)")
} catch {
    throw error
}
```

## API Reference

### `RecommendAIClient`

| Method | Returns | Description |
|---|---|---|
| `ping()` | `async -> Bool` | `true` if API is healthy |

### `recommendations` (property)

| Method | Returns |
|---|---|
| `similar(itemId:, limit:)` | `async throws -> [Recommendation]` |
| `popular(limit:, category:)` | `async throws -> [Recommendation]` |

### `items` (property)

| Method | Returns |
|---|---|
| `upsert(items:)` | `async throws -> [Item]` |

### `RecommendAIError`

| Case | Triggered by |
|---|---|
| `.authentication(String)` | HTTP 401 |
| `.notFound(String)` | HTTP 404 |
| `.validation(String)` | HTTP 422 |
| `.rateLimit(String)` | HTTP 429 |
| `.server(String, statusCode:)` | HTTP 5xx |
