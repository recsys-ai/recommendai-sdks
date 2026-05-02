# RecSys.AI Swift SDK

Official Swift client for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- Swift 5.9 / Xcode 15+
- macOS 13+

## Installation

### Swift Package Manager

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/recsys-ai/recommendai-swift", from: "1.0.0"),
],
targets: [
    .target(dependencies: [
        .product(name: "RecommendAI", package: "recommendai-swift"),
    ]),
]
```

## Quick Start

```swift
import RecommendAI

let client = RecommendAIClient(apiKey: "your_api_key")

// Create a user
let user = try await client.users.create(userId: "user-123",
    properties: ["name": "Alice", "age": 28])

// Record an interaction
_ = try await client.interactions.create(
    userId: "user-123", itemId: "item-456", type: .view)

// Get recommendations
let recs = try await client.recommendations.get(userId: "user-123", limit: 10)
for r in recs {
    print("\(r.itemId): \(String(format: "%.4f", r.score))  \(r.reason)")
}
```

## Configuration

```swift
let config = ClientConfig(
    baseURL: "https://api.recsys-ai.com",
    timeout: 30
)
let client = RecommendAIClient(apiKey: "your_api_key", config: config)
```

## API Reference

### Recommendations

```swift
let recs = try await client.recommendations.get(userId: "user-123", limit: 10)
```

### Users

```swift
try await client.users.create(userId: "user-123", properties: ["name": "Alice"])
try await client.users.get(userId: "user-123")
try await client.users.update(userId: "user-123", properties: ["subscription": "premium"])
try await client.users.delete(userId: "user-123")
```

### Items

```swift
try await client.items.create(itemId: "item-456", properties: ["title": "Inception"])
try await client.items.get(itemId: "item-456")
try await client.items.update(itemId: "item-456", properties: ["remastered": true])
try await client.items.delete(itemId: "item-456")
```

### Interactions

```swift
_ = try await client.interactions.create(
    userId: "user-123", itemId: "item-456", type: .rating, value: 8.5)
```

Available types: `.view`, `.like`, `.dislike`, `.purchase`, `.rating`, `.share`, `.bookmark`

## Error Handling

```swift
do {
    _ = try await client.users.get(userId: "ghost")
} catch RecommendAIError.notFound(let msg) {
    print("Not found: \(msg)")
} catch RecommendAIError.authentication(let msg) {
    print("Auth error: \(msg)")
} catch RecommendAIError.rateLimit(let msg) {
    print("Rate limited: \(msg)")
} catch {
    print("Unexpected: \(error)")
}
```

## Running the Simulation

The simulation uses a `URLProtocol` interceptor — no real server or port is opened.
All HTTP calls are handled in-process.

```bash
swift run RecommendAISimulation
```

## License

MIT
