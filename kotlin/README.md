# RecSys.AI Kotlin SDK

Official Kotlin client for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- JDK 11+
- Kotlin 1.9+
- Gradle 8+

## Installation

Add to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.recommendai:recommendai-sdk:1.0.0")
}
```

## Quick Start

```kotlin
import com.recommendai.sdk.*

val client = RecommendAIClient(apiKey = "your_api_key")

// Create a user
val user = client.users.create("user-123", mapOf(
    "name" to "Alice", "age" to 28
))

// Record an interaction
client.interactions.create("user-123", "item-456", InteractionType.view)

// Get recommendations
val recs = client.recommendations.get("user-123", limit = 10)
recs.forEach { r -> println("${r.itemId}: ${"%.4f".format(r.score)}  ${r.reason}") }
```

## Configuration

```kotlin
val client = RecommendAIClient(
    apiKey = "your_api_key",
    config = ClientConfig(
        baseUrl        = "https://api.recsys-ai.com",
        timeoutSeconds = 30,
    )
)
```

## API Reference

### Recommendations

```kotlin
val recs: List<Recommendation> = client.recommendations.get("user-123", limit = 10)
```

### Users

```kotlin
client.users.create("user-123", mapOf("name" to "Alice"))
client.users.get("user-123")
client.users.update("user-123", mapOf("subscription" to "premium"))
client.users.delete("user-123")
```

### Items

```kotlin
client.items.create("item-456", mapOf("title" to "Inception", "genre" to "sci-fi"))
client.items.get("item-456")
client.items.update("item-456", mapOf("remastered" to true))
client.items.delete("item-456")
```

### Interactions

```kotlin
client.interactions.create("user-123", "item-456", InteractionType.view)
client.interactions.create("user-123", "item-456", InteractionType.rating, value = 8.5)
```

Available interaction types: `view`, `like`, `dislike`, `purchase`, `rating`, `share`, `bookmark`

## Error Handling

```kotlin
try {
    client.users.get("ghost")
} catch (e: NotFoundException) {
    println("Not found: ${e.message}")
} catch (e: AuthenticationException) {
    println("Auth error: ${e.message}")
} catch (e: RateLimitException) {
    println("Rate limited")
} catch (e: RecommendAIException) {
    println("API error [${e.statusCode}]: ${e.message}")
}
```

## Running the Simulation

The simulation starts a `com.sun.net.httpserver.HttpServer` mock on port 17898.  
No live API key or service is required.

```bash
./gradlew run
```

## License

MIT
