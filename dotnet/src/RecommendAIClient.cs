using System.Net.Http.Headers;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

[assembly: InternalsVisibleTo("RecommendAI.Tests")]

namespace RecommendAI;

/// <summary>
/// Official .NET client for the RecSys.AI personalised-recommendation platform.
/// </summary>
public sealed class RecommendAIClient : IDisposable
{
    internal HttpClient Http;

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition      = JsonIgnoreCondition.WhenWritingNull,
        Converters = { new JsonStringEnumConverter() },
    };

    /// <summary>Access recommendations endpoints.</summary>
    public RecommendationsResource Recommendations { get; }
    /// <summary>Access user management endpoints.</summary>
    public UsersResource Users { get; }
    /// <summary>Access item catalogue endpoints.</summary>
    public ItemsResource Items { get; }
    /// <summary>Access interaction recording endpoints.</summary>
    public InteractionsResource Interactions { get; }

    /// <summary>Creates a new client.</summary>
    /// <param name="apiKey">Your RecSys.AI API key.</param>
    /// <param name="baseUrl">Override the default API base URL.</param>
    /// <param name="timeout">HTTP request timeout (default 30 s).</param>
    public RecommendAIClient(
        string apiKey,
        string baseUrl = "http://localhost:8080",
        TimeSpan? timeout = null)
    {
        Http = new HttpClient
        {
            BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/"),
            Timeout     = timeout ?? TimeSpan.FromSeconds(30),
        };
        Http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);
        Http.DefaultRequestHeaders.UserAgent.ParseAdd("recommendai-dotnet/1.0.0");

        Recommendations = new RecommendationsResource(this);
        Users           = new UsersResource(this);
        Items           = new ItemsResource(this);
        Interactions    = new InteractionsResource(this);
    }

    /// <summary>Internal constructor for testing — injects a custom message handler.</summary>
    internal RecommendAIClient(string apiKey, HttpMessageHandler handler)
    {
        Http = new HttpClient(handler)
        {
            BaseAddress = new Uri("http://localhost:8080/"),
        };
        Http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);
        Http.DefaultRequestHeaders.UserAgent.ParseAdd("recommendai-dotnet/1.0.0");

        Recommendations = new RecommendationsResource(this);
        Users           = new UsersResource(this);
        Items           = new ItemsResource(this);
        Interactions    = new InteractionsResource(this);
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    internal static StringContent ToJson(object payload)
        => new(JsonSerializer.Serialize(payload, JsonOpts), Encoding.UTF8, "application/json");

    internal async Task<T> SendAsync<T>(HttpRequestMessage request)
    {
        var response = await Http.SendAsync(request).ConfigureAwait(false);
        var body     = await response.Content.ReadAsStringAsync().ConfigureAwait(false);

        if (!response.IsSuccessStatusCode)
            throw BuildException((int)response.StatusCode, body);

        if (response.StatusCode == System.Net.HttpStatusCode.NoContent || string.IsNullOrWhiteSpace(body))
            return default!;

        return JsonSerializer.Deserialize<T>(body, JsonOpts)
               ?? throw new RecommendAIException("Empty response body");
    }

    internal async Task SendAsync(HttpRequestMessage request)
    {
        var response = await Http.SendAsync(request).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
            throw BuildException((int)response.StatusCode, body);
        }
    }

    private static RecommendAIException BuildException(int status, string body)
    {
        string detail = ExtractDetail(body) ?? $"HTTP {status}";
        return status switch
        {
            401                  => new AuthenticationException(detail),
            404                  => new NotFoundException(detail),
            400 or 422           => new ValidationException(detail, status),
            429                  => new RateLimitException(detail),
            >= 500 and <= 599    => new ServerException(detail, status),
            _                    => new RecommendAIException(detail, status),
        };
    }

    private static string? ExtractDetail(string body)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            if (doc.RootElement.TryGetProperty("detail", out var d))
                return d.GetString();
        }
        catch { /* fall through */ }
        return null;
    }

    /// <summary>Returns true if the API is reachable.</summary>
    public async Task<bool> PingAsync()
    {
        try
        {
            var req      = new HttpRequestMessage(HttpMethod.Get, "health");
            var response = await Http.SendAsync(req).ConfigureAwait(false);
            return response.IsSuccessStatusCode;
        }
        catch { return false; }
    }

    /// <inheritdoc />
    public void Dispose() => Http.Dispose();
}
