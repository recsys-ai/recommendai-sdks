# .NET SDK

## Installation

```bash
dotnet add package RecommendAI
```

Or via the NuGet Package Manager:

```
Install-Package RecommendAI
```

Requires .NET 6+.

## Quick Start

```csharp
using RecommendAI;

var client = new RecommendAIClient("your_api_key");

// Health check
bool alive = await client.PingAsync(); // true

// Similar items
var similar = await client.Recommendations.SimilarAsync("item-123", limit: 10);
foreach (var r in similar)
    Console.WriteLine($"{r.ItemId}  {r.Score}");

// Popular items
var popular = await client.Recommendations.PopularAsync(limit: 5, category: "books");

// Bulk upsert
var items = await client.Items.UpsertAsync(new[]
{
    new { item_id = "item-1", properties = new { title = "Book A" } },
});
```

## Configuration

```csharp
var client = new RecommendAIClient("your_api_key", new ClientConfig
{
    BaseUrl = "https://api.recsys.ai",
    TimeoutSeconds = 30,
});
```

## Error Handling

```csharp
using RecommendAI.Exceptions;

try
{
    var recs = await client.Recommendations.SimilarAsync("item-123");
}
catch (AuthenticationException)
{
    Console.Error.WriteLine("Invalid API key");
}
catch (NotFoundException)
{
    Console.Error.WriteLine("Item not found");
}
catch (RateLimitException)
{
    Console.Error.WriteLine("Rate limit exceeded");
}
```

## API Reference

### `RecommendAIClient`

| Method | Returns | Description |
|---|---|---|
| `PingAsync()` | `Task<bool>` | `true` if API is healthy |

### `Recommendations`

| Method | Returns |
|---|---|
| `SimilarAsync(itemId, limit)` | `Task<List<Recommendation>>` |
| `PopularAsync(limit, category?)` | `Task<List<Recommendation>>` |

### `Items`

| Method | Returns |
|---|---|
| `UpsertAsync(items)` | `Task<List<Item>>` |
