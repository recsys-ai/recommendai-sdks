# Getting Started

## Prerequisites

Sign up at [recsys.ai](https://recsys.ai) to get an API key.

## Quick Install

=== "Python"
    ```bash
    pip install recommendai
    ```

=== "TypeScript"
    ```bash
    npm install @recommendai/sdk
    ```

=== "Go"
    ```bash
    go get github.com/recsys-ai/recommendai-sdkss/go
    ```

=== "Dart"
    ```bash
    dart pub add recommendai
    ```

=== ".NET"
    ```bash
    dotnet add package RecommendAI
    ```

=== "Java"
    ```xml
    <dependency>
      <groupId>com.recommendai</groupId>
      <artifactId>recommendai-sdk</artifactId>
      <version>1.0.0</version>
    </dependency>
    ```

=== "Kotlin"
    ```kotlin
    implementation("com.recommendai:recommendai-sdk-kotlin:1.0.0")
    ```

=== "PHP"
    ```bash
    composer require recsys-ai/recommendai
    ```

=== "Ruby"
    ```bash
    gem install recommendai
    ```

=== "Rust"
    ```toml
    [dependencies]
    recommendai = "1"
    ```

=== "Swift"
    ```swift
    // Package.swift
    .package(url: "https://github.com/recsys-ai/recommendai-sdks", from: "1.0.0")
    ```

## Basic Usage

=== "Python"
    ```python
    from recommendai import RecommendAIClient

    client = RecommendAIClient(api_key="your_api_key")

    # Similar items
    similar = client.recommendations.similar("item-123", limit=10)

    # Popular items
    popular = client.recommendations.popular(limit=10, category="electronics")

    # Health check
    if client.ping():
        print("API is reachable")
    ```

=== "TypeScript"
    ```typescript
    import { RecommendAIClient } from "@recommendai/sdk";

    const client = new RecommendAIClient({ apiKey: "your_api_key" });

    const similar = await client.recommendations.similar({ itemId: "item-123", limit: 10 });
    const popular = await client.recommendations.popular({ limit: 10, category: "electronics" });

    const alive = await client.ping();
    ```

=== "Go"
    ```go
    import "github.com/recsys-ai/recommendai-sdkss/go/recommendai"

    client := recommendai.NewClient("your_api_key")

    similar, err := client.Recommendations.Similar(ctx, "item-123", 10)
    popular, err := client.Recommendations.Popular(ctx, 10, "electronics")

    ok, err := client.Ping(ctx)
    ```

=== "Dart"
    ```dart
    import 'package:recommendai/recommendai.dart';

    final client = RecommendAIClient(apiKey: 'your_api_key');

    final similar = await client.recommendations.similar('item-123', limit: 10);
    final popular = await client.recommendations.popular(limit: 10, category: 'electronics');

    final alive = await client.ping();
    ```

=== ".NET"
    ```csharp
    using RecommendAI;

    using var client = new RecommendAIClient("your_api_key");

    var similar = await client.Recommendations.SimilarAsync("item-123", limit: 10);
    var popular = await client.Recommendations.PopularAsync(limit: 10, category: "electronics");

    bool alive = await client.PingAsync();
    ```

=== "Java"
    ```java
    import com.recommendai.sdk.RecommendAIClient;

    RecommendAIClient client = new RecommendAIClient("your_api_key");

    var similar = client.recommendations().similar("item-123", 10);
    var popular = client.recommendations().popular(10, "electronics");

    boolean alive = client.ping();
    ```

=== "Kotlin"
    ```kotlin
    import com.recommendai.sdk.RecommendAIClient

    val client = RecommendAIClient("your_api_key")

    val similar = client.recommendations.similar("item-123", limit = 10)
    val popular = client.recommendations.popular(limit = 10, category = "electronics")

    val alive = client.ping()
    ```

=== "PHP"
    ```php
    use RecommendAI\RecommendAIClient;

    $client = new RecommendAIClient('your_api_key');

    $similar = $client->recommendations()->similar('item-123', 10);
    $popular = $client->recommendations()->popular(10, 'electronics');

    $alive = $client->ping();
    ```

=== "Ruby"
    ```ruby
    require 'recommendai'

    client = RecommendAI::Client.new(api_key: 'your_api_key')

    similar = client.recommendations.similar('item-123', limit: 10)
    popular = client.recommendations.popular(limit: 10, category: 'electronics')

    alive = client.ping
    ```

=== "Rust"
    ```rust
    use recommendai::RecommendAIClient;

    let client = RecommendAIClient::new("your_api_key");

    let similar = client.recommendations().similar("item-123", 10)?;
    let popular = client.recommendations().popular(10, Some("electronics"))?;

    let alive = client.ping();
    ```

=== "Swift"
    ```swift
    import RecommendAI

    let client = RecommendAIClient(apiKey: "your_api_key")

    let similar = try await client.recommendations.similar(itemId: "item-123", limit: 10)
    let popular = try await client.recommendations.popular(limit: 10, category: "electronics")

    let alive = await client.ping()
    ```

## Authentication

All requests require a Bearer token:

```
Authorization: Bearer <api_key>
```

Pass your API key to the client constructor — the SDK handles the header automatically.

## Error Handling

All SDKs throw/return typed errors for common HTTP status codes:

| HTTP Status | Error Type |
|---|---|
| 401 | `AuthenticationError` / `AuthenticationException` |
| 404 | `NotFoundError` / `NotFoundException` |
| 422 | `ValidationError` / `ValidationException` |
| 429 | `RateLimitError` / `RateLimitException` |
| 5xx | `ServerError` / `ServerException` |

See the per-language pages for exact type names and catch patterns.

## API Reference

The base URL defaults to `http://localhost:8080` for local development. Set it via the client config for production:

=== "Python"
    ```python
    client = RecommendAIClient(api_key="key", base_url="https://api.recsys.ai")
    ```

=== "TypeScript"
    ```typescript
    const client = new RecommendAIClient({ apiKey: "key", baseUrl: "https://api.recsys.ai" });
    ```

=== "Go"
    ```go
    client := recommendai.NewClient("key", recommendai.WithBaseURL("https://api.recsys.ai"))
    ```

=== "Dart"
    ```dart
    final client = RecommendAIClient(apiKey: 'key', baseUrl: 'https://api.recsys.ai');
    ```

=== ".NET"
    ```csharp
    using var client = new RecommendAIClient(apiKey: "key", baseUrl: "https://api.recsys.ai");
    ```

=== "Java"
    ```java
    RecommendAIClient client = new RecommendAIClient("key", "https://api.recsys.ai");
    ```

=== "Kotlin"
    ```kotlin
    val client = RecommendAIClient("key", ClientConfig(baseUrl = "https://api.recsys.ai"))
    ```

=== "PHP"
    ```php
    $client = new RecommendAIClient('key', 'https://api.recsys.ai');
    ```

=== "Ruby"
    ```ruby
    client = RecommendAI::Client.new(api_key: 'key', base_url: 'https://api.recsys.ai')
    ```

=== "Rust"
    ```rust
    let client = RecommendAIClient::builder("key")
        .base_url("https://api.recsys.ai")
        .build();
    ```

=== "Swift"
    ```swift
    let client = RecommendAIClient(apiKey: "key", config: ClientConfig(baseURL: "https://api.recsys.ai"))
    ```
