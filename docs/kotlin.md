# Kotlin SDK

## Installation

### Gradle (Kotlin DSL)

```kotlin
implementation("com.recommendai:recommendai-sdk-kotlin:1.0.0")
```

### Gradle (Groovy DSL)

```groovy
implementation 'com.recommendai:recommendai-sdk-kotlin:1.0.0'
```

Requires Kotlin 1.9+ / JVM 11+.

## Quick Start

```kotlin
import com.recommendai.sdk.RecommendAIClient
import com.recommendai.sdk.ClientConfig

fun main() {
    val client = RecommendAIClient(apiKey = "your_api_key")

    // Health check
    println(client.ping()) // true

    // Similar items
    val similar = client.recommendations.similar("item-123", limit = 10)
    similar.forEach { println("${it.itemId}  ${it.score}") }

    // Popular items
    val popular = client.recommendations.popular(limit = 5, category = "books")

    // Bulk upsert
    client.items.upsert(listOf(
        mapOf("item_id" to "item-1", "properties" to mapOf("title" to "Book A"))
    ))
}
```

## Configuration

```kotlin
val client = RecommendAIClient(
    apiKey = "your_api_key",
    config = ClientConfig(
        baseUrl = "https://api.recsys.ai",
        timeoutSeconds = 30,
    )
)
```

## Error Handling

```kotlin
import com.recommendai.sdk.exceptions.*

try {
    val recs = client.recommendations.similar("item-123")
} catch (e: AuthenticationException) {
    println("Invalid API key")
} catch (e: NotFoundException) {
    println("Item not found")
} catch (e: RateLimitException) {
    println("Rate limit exceeded")
}
```

## API Reference

### `RecommendAIClient`

| Method | Returns | Description |
|---|---|---|
| `ping()` | `Boolean` | `true` if API is healthy |

### `recommendations` (property)

| Method | Returns |
|---|---|
| `similar(itemId, limit)` | `List<Recommendation>` |
| `popular(limit, category?)` | `List<Recommendation>` |

### `items` (property)

| Method | Returns |
|---|---|
| `upsert(items)` | `List<Item>` |
