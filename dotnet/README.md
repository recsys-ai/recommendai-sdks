# RecSys.AI .NET SDK

Official .NET client for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- .NET 8+

## Installation

```bash
dotnet add package RecommendAI
```

## Quick Start

```csharp
using RecommendAI;

using var client = new RecommendAIClient("your_api_key");

// Create a user
var user = await client.Users.CreateAsync("user-123", new() {
    ["name"] = "Alice",
    ["age"]  = 28,
});

// Add an item to the catalogue
var item = await client.Items.CreateAsync("item-456", new() {
    ["title"] = "Inception",
    ["genre"] = "sci-fi",
});

// Record an interaction
await client.Interactions.CreateAsync("user-123", "item-456", InteractionType.View);

// Get recommendations
var recs = await client.Recommendations.GetAsync("user-123", limit: 10);
foreach (var r in recs)
    Console.WriteLine($"{r.ItemId}  score={r.Score:F4}  {r.Reason}");
```

## Configuration

```csharp
// Custom base URL + timeout
using var client = new RecommendAIClient(
    apiKey:  "your_api_key",
    baseUrl: "https://api.recsys-ai.com",
    timeout: TimeSpan.FromSeconds(15));
```

## API Reference

### Recommendations

```csharp
IReadOnlyList<Recommendation> recs = await client.Recommendations.GetAsync("user-123", limit: 10);
```

### Users

```csharp
var user = await client.Users.CreateAsync("user-123", props);
var user = await client.Users.GetAsync("user-123");
var user = await client.Users.UpdateAsync("user-123", props);
await client.Users.DeleteAsync("user-123");
```

### Items

```csharp
var item = await client.Items.CreateAsync("item-456", props);
var item = await client.Items.GetAsync("item-456");
var item = await client.Items.UpdateAsync("item-456", props);
await client.Items.DeleteAsync("item-456");
```

### Interactions

```csharp
// Simple
await client.Interactions.CreateAsync("user-123", "item-456", InteractionType.View);

// With rating
await client.Interactions.CreateAsync("user-123", "item-456", InteractionType.Rating, value: 8.5);
```

Available `InteractionType` values: `View`, `Click`, `Purchase`, `Like`, `Dislike`,
`Rating`, `CartAdd`, `CartRemove`.

## Error Handling

```csharp
try
{
    var user = await client.Users.GetAsync("ghost");
}
catch (NotFoundException ex)
{
    Console.WriteLine($"Not found: {ex.Message}");
}
catch (AuthenticationException ex)
{
    Console.WriteLine($"Auth error: {ex.Message}");
}
catch (RateLimitException ex)
{
    Console.WriteLine($"Rate limited: {ex.Message}");
}
catch (RecommendAIException ex)
{
    Console.WriteLine($"API error ({ex.StatusCode}): {ex.Message}");
}
```

## Running the Simulation Example

The simulation starts an in-process `HttpListener` mock server on port 17894
and exercises the full SDK — no live API key or service required.

```bash
cd recommendai-sdks/dotnet
dotnet run --project examples/Simulation.csproj
```

## License

MIT
