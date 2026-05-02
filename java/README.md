# RecSys.AI Java SDK

Official Java SDK for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- Java 11 or later
- Maven 3.6+

## Installation

Add the following dependency to your `pom.xml`:

```xml
<dependency>
  <groupId>com.recommendai</groupId>
  <artifactId>recommendai-sdk</artifactId>
  <version>1.0.0</version>
</dependency>
```

## Quick Start

```java
import com.recommendai.sdk.RecommendAIClient;
import com.recommendai.sdk.models.*;

RecommendAIClient client = new RecommendAIClient("your_api_key");

// Create a user
User user = client.users().create("user-123", Map.of("name", "Alice"));

// Add a catalogue item
Item item = client.items().create("item-456", Map.of("title", "Inception", "genre", "sci-fi"));

// Record an interaction
client.interactions().create("user-123", "item-456", InteractionType.VIEW);

// Get personalised recommendations
List<Recommendation> recs = client.recommendations().get("user-123", 10);
for (Recommendation r : recs) {
    System.out.printf("%s  score=%.4f  %s%n", r.getItemId(), r.getScore(), r.getReason());
}
```

## Configuration

```java
import java.time.Duration;

// Default base URL (http://localhost:8080) + 30 s timeout
RecommendAIClient client = new RecommendAIClient("your_api_key");

// Custom base URL
RecommendAIClient client = new RecommendAIClient("your_api_key", "https://api.recsys-ai.com");

// Custom base URL + timeout
RecommendAIClient client = new RecommendAIClient(
        "your_api_key",
        "https://api.recsys-ai.com",
        Duration.ofSeconds(10));
```

## API Reference

### Recommendations

```java
// Get recommendations (limit defaults to 10)
List<Recommendation> recs = client.recommendations().get("user-123");

// Get up to 20 recommendations
List<Recommendation> recs = client.recommendations().get("user-123", 20);
```

Each `Recommendation` has:
- `getItemId()` – the recommended item
- `getScore()` – relevance score (0–1)
- `getReason()` – human-readable explanation
- `getMetadata()` – extra fields from the server

### Users

```java
// Create
User user = client.users().create("user-123", Map.of("name", "Alice", "age", 28));

// Read
User user = client.users().get("user-123");

// Update
User user = client.users().update("user-123", Map.of("subscription", "premium"));

// Delete
client.users().delete("user-123");
```

### Items

```java
// Create
Item item = client.items().create("item-456", Map.of("title", "Inception", "genre", "sci-fi"));

// Read
Item item = client.items().get("item-456");

// Update
Item item = client.items().update("item-456", Map.of("title", "Inception", "remastered", true));

// Delete
client.items().delete("item-456");
```

### Interactions

```java
import com.recommendai.sdk.models.InteractionType;

// Simple interaction
client.interactions().create("user-123", "item-456", InteractionType.VIEW);

// Interaction with numeric value (e.g. a rating)
client.interactions().create("user-123", "item-456", InteractionType.RATING, 8.5);

// Interaction with value and metadata
client.interactions().create("user-123", "item-456", InteractionType.RATING, 8.5,
        Map.of("source", "mobile-app"));
```

Available `InteractionType` values: `VIEW`, `CLICK`, `PURCHASE`, `LIKE`, `DISLIKE`,
`RATING`, `CART_ADD`, `CART_REMOVE`.

## Error Handling

All SDK methods throw checked `IOException` / `InterruptedException` for I/O failures.
API-level errors throw unchecked subclasses of `RecommendAIException`:

| Exception | HTTP Status |
|---|---|
| `AuthenticationException` | 401 |
| `NotFoundException` | 404 |
| `ValidationException` | 400, 422 |
| `RateLimitException` | 429 |
| `ServerException` | 5xx |

```java
import com.recommendai.sdk.exceptions.*;

try {
    User user = client.users().get("unknown-id");
} catch (NotFoundException e) {
    System.out.println("User not found: " + e.getMessage());
} catch (AuthenticationException e) {
    System.out.println("Invalid API key");
} catch (RecommendAIException e) {
    System.out.println("API error (" + e.getStatusCode() + "): " + e.getMessage());
} catch (IOException | InterruptedException e) {
    System.out.println("Network error: " + e.getMessage());
}
```

## Running the Simulation Example

The simulation starts an in-process mock server (port 17892) and exercises the
full SDK workflow — no live API key or running service required.

```bash
mvn package -q
java -jar target/recommendai-sdk-1.0.0.jar
```

## Development

```bash
# Compile
mvn compile

# Run tests
mvn test

# Build fat JAR
mvn package
```

## License

MIT
