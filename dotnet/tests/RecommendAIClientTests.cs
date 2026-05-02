using System.Net;
using System.Text.Json;
using RichardSzalay.MockHttp;
using Xunit;

namespace RecommendAI.Tests;

public sealed class RecommendAIClientTests
{
    // ── helpers ──────────────────────────────────────────────────────────────

    private static string Json(object obj) => JsonSerializer.Serialize(obj);

    private static (MockHttpMessageHandler mock, RecommendAIClient client) CreatePair()
    {
        var mock   = new MockHttpMessageHandler();
        var client = new RecommendAIClient("test-key", mock);
        return (mock, client);
    }

    // ── ping ─────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Ping_ReturnsTrue_WhenServerResponds200()
    {
        var (mock, client) = CreatePair();
        mock.When("http://localhost:8080/health")
            .Respond(HttpStatusCode.OK);

        Assert.True(await client.PingAsync());
        mock.VerifyNoOutstandingExpectation();
    }

    [Fact]
    public async Task Ping_ReturnsFalse_WhenServerResponds503()
    {
        var (mock, client) = CreatePair();
        mock.When("http://localhost:8080/health")
            .Respond(HttpStatusCode.ServiceUnavailable);

        Assert.False(await client.PingAsync());
    }

    // ── recommendations ───────────────────────────────────────────────────────

    [Fact]
    public async Task Recommendations_GetAsync_ReturnsItems()
    {
        var (mock, client) = CreatePair();
        mock.When("http://localhost:8080/api/recommendations*")
            .Respond("application/json", Json(new
            {
                recommendations = new[] { new { item_id = "item1", score = 0.9, reason = "test", metadata = new { } } }
            }));

        var recs = await client.Recommendations.GetAsync("user1", 5);
        Assert.Single(recs);
        Assert.Equal("item1", recs[0].ItemId);
    }

    [Fact]
    public async Task Recommendations_SimilarAsync_CallsCorrectPath()
    {
        var (mock, client) = CreatePair();
        mock.When("http://localhost:8080/api/recommendations/similar/item99*")
            .Respond("application/json", Json(new
            {
                recommendations = new[] { new { item_id = "item2", score = 0.8, reason = "", metadata = new { } } }
            }));

        var recs = await client.Recommendations.SimilarAsync("item99", 10);
        Assert.Single(recs);
        Assert.Equal("item2", recs[0].ItemId);
    }

    [Fact]
    public async Task Recommendations_PopularAsync_PassesCategoryParam()
    {
        var (mock, client) = CreatePair();
        mock.When("http://localhost:8080/api/recommendations/popular*")
            .WithQueryString("category", "books")
            .Respond("application/json", Json(new
            {
                recommendations = new[] { new { item_id = "book1", score = 0.7, reason = "", metadata = new { } } }
            }));

        var recs = await client.Recommendations.PopularAsync(5, "books");
        Assert.Single(recs);
    }

    // ── items ─────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Items_UpsertAsync_PostsToBulkEndpoint()
    {
        var (mock, client) = CreatePair();
        mock.When(HttpMethod.Post, "http://localhost:8080/api/items/bulk")
            .Respond("application/json", Json(new
            {
                items = new[] { new { item_id = "itemA", properties = new { }, created_at = "2024-01-01T00:00:00Z", updated_at = "2024-01-01T00:00:00Z" } }
            }));

        var items = await client.Items.UpsertAsync(new[]
        {
            new Dictionary<string, object?> { ["item_id"] = "itemA", ["properties"] = new Dictionary<string, object?> { ["name"] = "Book A" } }
        });
        Assert.Single(items);
        Assert.Equal("itemA", items[0].ItemId);
    }

    // ── error handling ────────────────────────────────────────────────────────

    [Fact]
    public async Task AuthenticationException_ThrownOn401()
    {
        var (mock, client) = CreatePair();
        mock.When("http://localhost:8080/api/recommendations*")
            .Respond(HttpStatusCode.Unauthorized, "application/json",
                     Json(new { detail = "invalid api key" }));

        await Assert.ThrowsAsync<AuthenticationException>(
            () => client.Recommendations.GetAsync("u", 5));
    }

    [Fact]
    public async Task NotFoundException_ThrownOn404()
    {
        var (mock, client) = CreatePair();
        mock.When("http://localhost:8080/api/recommendations*")
            .Respond(HttpStatusCode.NotFound, "application/json",
                     Json(new { detail = "not found" }));

        await Assert.ThrowsAsync<NotFoundException>(
            () => client.Recommendations.GetAsync("u", 5));
    }

    [Fact]
    public async Task RateLimitException_ThrownOn429()
    {
        var (mock, client) = CreatePair();
        mock.When("http://localhost:8080/api/recommendations*")
            .Respond((HttpStatusCode)429, "application/json",
                     Json(new { detail = "rate limit exceeded" }));

        await Assert.ThrowsAsync<RateLimitException>(
            () => client.Recommendations.GetAsync("u", 5));
    }
}
