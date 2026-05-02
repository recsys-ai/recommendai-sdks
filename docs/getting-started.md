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
    go get github.com/recsys-ai/recommendai-sdk/go
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
    composer require recommendai/sdk
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
    .package(url: "https://github.com/recsys-ai/recommendai-sdk", from: "1.0.0")
    ```

## Basic Usage

=== "Python"
    ```python
    from recommendai import RecommendAIClient

    client = RecommendAIClient(api_key="your_api_key")

    # Similar items
    recs = client.recommendations.similar("item-123", limit=10)

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

    const similar = await client.recommendations.similar("item-123", { limit: 10 });
    const popular = await client.recommendations.popular({ limit: 10, category: "electronics" });

    const alive = await client.ping();
    ```

=== "Go"
    ```go
    import "github.com/recsys-ai/recommendai-sdk/go/recommendai"

    client := recommendai.NewClient("your_api_key")

    similar, err := client.Recommendations.Similar(ctx, "item-123", 10)
    popular, err := client.Recommendations.Popular(ctx, 10, "electronics")

    ok, err := client.Ping(ctx)
    ```

=== "Rust"
    ```rust
    use recommendai::RecommendAIClient;

    let client = RecommendAIClient::new("your_api_key");

    let similar = client.recommendations().similar("item-123", 10)?;
    let popular = client.recommendations().popular(10, Some("electronics"))?;

    let alive = client.ping();
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
