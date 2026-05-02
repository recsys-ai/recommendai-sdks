using System.Text.Json.Serialization;

namespace RecommendAI;

// ── Recommendations ───────────────────────────────────────────────────────────

public sealed class RecommendationsResource(RecommendAIClient client)
{
    /// <summary>Returns personalised recommendations for a user.</summary>
    public async Task<IReadOnlyList<Recommendation>> GetAsync(string userId, int limit = 10)
    {
        var req = new HttpRequestMessage(HttpMethod.Get,
            $"api/recommendations?user_id={Uri.EscapeDataString(userId)}&limit={limit}");
        var resp = await client.SendAsync<RecommendationsResponse>(req).ConfigureAwait(false);
        return resp.Recommendations ?? [];
    }

    /// <summary>Returns items similar to the given item.</summary>
    public async Task<IReadOnlyList<Recommendation>> SimilarAsync(string itemId, int limit = 10)
    {
        var req = new HttpRequestMessage(HttpMethod.Get,
            $"api/recommendations/similar/{Uri.EscapeDataString(itemId)}?limit={limit}");
        var resp = await client.SendAsync<RecommendationsResponse>(req).ConfigureAwait(false);
        return resp.Recommendations ?? [];
    }

    /// <summary>Returns globally popular items, optionally filtered by category.</summary>
    public async Task<IReadOnlyList<Recommendation>> PopularAsync(int limit = 10, string? category = null)
    {
        var url = $"api/recommendations/popular?limit={limit}";
        if (!string.IsNullOrEmpty(category)) url += $"&category={Uri.EscapeDataString(category!)}";
        var req = new HttpRequestMessage(HttpMethod.Get, url);
        var resp = await client.SendAsync<RecommendationsResponse>(req).ConfigureAwait(false);
        return resp.Recommendations ?? [];
    }

    private sealed class RecommendationsResponse
    {
        [JsonPropertyName("recommendations")] public List<Recommendation>? Recommendations { get; init; }
    }
}

// ── Users ─────────────────────────────────────────────────────────────────────

public sealed class UsersResource(RecommendAIClient client)
{
    /// <summary>Registers a new user.</summary>
    public Task<User> CreateAsync(string userId, Dictionary<string, object?>? properties = null)
    {
        var body = new Dictionary<string, object?> { ["user_id"] = userId, ["properties"] = properties ?? [] };
        var req  = new HttpRequestMessage(HttpMethod.Post, "api/users") { Content = RecommendAIClient.ToJson(body) };
        return client.SendAsync<User>(req);
    }

    /// <summary>Retrieves a user by ID.</summary>
    public Task<User> GetAsync(string userId)
    {
        var req = new HttpRequestMessage(HttpMethod.Get, $"api/users/{Uri.EscapeDataString(userId)}");
        return client.SendAsync<User>(req);
    }

    /// <summary>Updates a user's properties.</summary>
    public Task<User> UpdateAsync(string userId, Dictionary<string, object?> properties)
    {
        var body = new Dictionary<string, object?> { ["properties"] = properties };
        var req  = new HttpRequestMessage(HttpMethod.Put, $"api/users/{Uri.EscapeDataString(userId)}")
                   { Content = RecommendAIClient.ToJson(body) };
        return client.SendAsync<User>(req);
    }

    /// <summary>Permanently deletes a user.</summary>
    public Task DeleteAsync(string userId)
    {
        var req = new HttpRequestMessage(HttpMethod.Delete, $"api/users/{Uri.EscapeDataString(userId)}");
        return client.SendAsync(req);
    }
}

// ── Items ─────────────────────────────────────────────────────────────────────

public sealed class ItemsResource(RecommendAIClient client)
{
    /// <summary>Adds a new item to the catalogue.</summary>
    public Task<Item> CreateAsync(string itemId, Dictionary<string, object?>? properties = null)
    {
        var body = new Dictionary<string, object?> { ["item_id"] = itemId, ["properties"] = properties ?? [] };
        var req  = new HttpRequestMessage(HttpMethod.Post, "api/items") { Content = RecommendAIClient.ToJson(body) };
        return client.SendAsync<Item>(req);
    }

    /// <summary>Retrieves an item by ID.</summary>
    public Task<Item> GetAsync(string itemId)
    {
        var req = new HttpRequestMessage(HttpMethod.Get, $"api/items/{Uri.EscapeDataString(itemId)}");
        return client.SendAsync<Item>(req);
    }

    /// <summary>Updates an item's properties.</summary>
    public Task<Item> UpdateAsync(string itemId, Dictionary<string, object?> properties)
    {
        var body = new Dictionary<string, object?> { ["properties"] = properties };
        var req  = new HttpRequestMessage(HttpMethod.Put, $"api/items/{Uri.EscapeDataString(itemId)}")
                   { Content = RecommendAIClient.ToJson(body) };
        return client.SendAsync<Item>(req);
    }

    /// <summary>Permanently deletes an item.</summary>
    public Task DeleteAsync(string itemId)
    {
        var req = new HttpRequestMessage(HttpMethod.Delete, $"api/items/{Uri.EscapeDataString(itemId)}");
        return client.SendAsync(req);
    }

    /// <summary>Bulk creates or updates items.</summary>
    public async Task<IReadOnlyList<Item>> UpsertAsync(IEnumerable<Dictionary<string, object?>> items)
    {
        var body = new Dictionary<string, object?> { ["items"] = items };
        var req  = new HttpRequestMessage(HttpMethod.Post, "api/items/bulk") { Content = RecommendAIClient.ToJson(body) };
        var resp = await client.SendAsync<UpsertResponse>(req).ConfigureAwait(false);
        return resp.Items ?? [];
    }

    private sealed class UpsertResponse
    {
        [JsonPropertyName("items")] public List<Item>? Items { get; init; }
    }
}

// ── Interactions ──────────────────────────────────────────────────────────────

public sealed class InteractionsResource(RecommendAIClient client)
{
    /// <summary>Records a user–item interaction.</summary>
    public Task<Interaction> CreateAsync(
        string userId, string itemId, InteractionType type,
        double? value = null, Dictionary<string, object?>? metadata = null)
    {
        var body = new Dictionary<string, object?>
        {
            ["user_id"]          = userId,
            ["item_id"]          = itemId,
            ["interaction_type"] = type.ToString().ToLowerInvariant(),
            ["value"]            = value,
            ["metadata"]         = metadata,
        };
        var req = new HttpRequestMessage(HttpMethod.Post, "api/interactions")
                  { Content = RecommendAIClient.ToJson(body) };
        return client.SendAsync<Interaction>(req);
    }
}
