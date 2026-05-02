# Java SDK

## Installation

### Maven

```xml
<dependency>
    <groupId>com.recommendai</groupId>
    <artifactId>recommendai-sdk</artifactId>
    <version>1.0.0</version>
</dependency>
```

### Gradle

```groovy
implementation 'com.recommendai:recommendai-sdk:1.0.0'
```

Requires Java 11+.

## Quick Start

```java
import com.recommendai.sdk.RecommendAIClient;
import com.recommendai.sdk.models.Recommendation;

import java.util.List;
import java.util.Map;

public class Example {
    public static void main(String[] args) {
        RecommendAIClient client = new RecommendAIClient("your_api_key");

        // Health check
        boolean alive = client.ping(); // true

        // Similar items
        List<Recommendation> similar = client.recommendations().similar("item-123", 10);
        similar.forEach(r -> System.out.println(r.getItemId() + " " + r.getScore()));

        // Popular items
        List<Recommendation> popular = client.recommendations().popular(5, "books");

        // Bulk upsert
        client.items().upsert(List.of(
            Map.of("item_id", "item-1", "properties", Map.of("title", "Book A"))
        ));
    }
}
```

## Configuration

```java
import com.recommendai.sdk.ClientConfig;

RecommendAIClient client = new RecommendAIClient(
    "your_api_key",
    ClientConfig.builder()
        .baseUrl("https://api.recsys.ai")
        .timeoutSeconds(30)
        .build()
);
```

## Error Handling

```java
import com.recommendai.sdk.exceptions.*;

try {
    client.recommendations().similar("item-123", 10);
} catch (AuthenticationException e) {
    System.err.println("Invalid API key");
} catch (NotFoundException e) {
    System.err.println("Item not found");
} catch (RateLimitException e) {
    System.err.println("Rate limit exceeded");
}
```

## API Reference

### `RecommendAIClient`

| Method | Returns | Description |
|---|---|---|
| `ping()` | `boolean` | `true` if API is healthy |

### `recommendations()`

| Method | Returns |
|---|---|
| `similar(itemId, limit)` | `List<Recommendation>` |
| `popular(limit, category)` | `List<Recommendation>` |

### `items()`

| Method | Returns |
|---|---|
| `upsert(items)` | `List<Item>` |
