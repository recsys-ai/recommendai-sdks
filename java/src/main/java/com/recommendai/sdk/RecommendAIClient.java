package com.recommendai.sdk;

import com.recommendai.sdk.resources.InteractionsResource;
import com.recommendai.sdk.resources.ItemsResource;
import com.recommendai.sdk.resources.RecommendationsResource;
import com.recommendai.sdk.resources.UsersResource;

import java.time.Duration;

/**
 * Main entry point for the RecSys.AI Java SDK.
 *
 * <p>Example usage:
 * <pre>{@code
 * RecommendAIClient client = new RecommendAIClient("your_api_key");
 *
 * // Create a user
 * User user = client.users().create("user-123", Map.of("name", "Alice"));
 *
 * // Record an interaction
 * client.interactions().create("user-123", "item-456", InteractionType.VIEW);
 *
 * // Get recommendations
 * List<Recommendation> recs = client.recommendations().get("user-123", 10);
 * }</pre>
 */
public class RecommendAIClient {

    private static final String DEFAULT_BASE_URL = "http://localhost:8080";
    private static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(30);

    private final ApiHttpClient http;
    private final RecommendationsResource recommendations;
    private final UsersResource           users;
    private final ItemsResource           items;
    private final InteractionsResource    interactions;

    // ── Constructors ──────────────────────────────────────────────────────────

    /**
     * Create a client using the default base URL ({@code http://localhost:8080})
     * and a 30-second timeout.
     *
     * @param apiKey your RecSys.AI API key
     */
    public RecommendAIClient(String apiKey) {
        this(apiKey, DEFAULT_BASE_URL, DEFAULT_TIMEOUT);
    }

    /**
     * Create a client with a custom base URL.
     *
     * @param apiKey  your RecSys.AI API key
     * @param baseUrl base URL of the RecSys.AI API (e.g. {@code https://api.recsys-ai.com})
     */
    public RecommendAIClient(String apiKey, String baseUrl) {
        this(apiKey, baseUrl, DEFAULT_TIMEOUT);
    }

    /**
     * Create a client with a custom base URL and timeout.
     *
     * @param apiKey  your RecSys.AI API key
     * @param baseUrl base URL of the RecSys.AI API
     * @param timeout per-request timeout
     */
    public RecommendAIClient(String apiKey, String baseUrl, Duration timeout) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalArgumentException("apiKey must not be null or blank");
        }
        this.http             = new ApiHttpClient(baseUrl, apiKey, timeout);
        this.recommendations  = new RecommendationsResource(http);
        this.users            = new UsersResource(http);
        this.items            = new ItemsResource(http);
        this.interactions     = new InteractionsResource(http);
    }

    // ── Resource accessors ────────────────────────────────────────────────────

    /** Access the Recommendations resource. */
    public RecommendationsResource recommendations() { return recommendations; }

    /** Access the Users resource. */
    public UsersResource users() { return users; }

    /** Access the Items resource. */
    public ItemsResource items() { return items; }

    /** Access the Interactions resource. */
    public InteractionsResource interactions() { return interactions; }

    /**
     * Check whether the API is reachable.
     *
     * @return {@code true} if the health endpoint returns 200
     */
    public boolean ping() {
        try {
            http.get("/health");
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
