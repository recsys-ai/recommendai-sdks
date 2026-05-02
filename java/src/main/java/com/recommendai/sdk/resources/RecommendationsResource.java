package com.recommendai.sdk.resources;

import com.fasterxml.jackson.core.type.TypeReference;
import com.recommendai.sdk.ApiHttpClient;
import com.recommendai.sdk.models.Recommendation;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Provides access to the {@code /api/recommendations} endpoints.
 */
public class RecommendationsResource {

    private final ApiHttpClient http;

    public RecommendationsResource(ApiHttpClient http) {
        this.http = http;
    }

    /**
     * Retrieve personalised recommendations for a user.
     *
     * @param userId  the user to recommend items for
     * @param limit   maximum number of recommendations to return (default 10)
     * @return ordered list of {@link Recommendation} objects
     */
    public List<Recommendation> get(String userId, int limit)
            throws IOException, InterruptedException {

        String path = "/api/recommendations?user_id=" + userId + "&limit=" + limit;
        String json = http.get(path);

        Map<String, Object> response = http.mapper.readValue(
                json, new TypeReference<Map<String, Object>>() {});

        List<?> rawList = (List<?>) response.getOrDefault("recommendations", List.of());
        String listJson = http.mapper.writeValueAsString(rawList);
        return http.mapper.readValue(listJson, new TypeReference<List<Recommendation>>() {});
    }

    /**
     * Retrieve personalised recommendations for a user with the default limit of 10.
     */
    public List<Recommendation> get(String userId)
            throws IOException, InterruptedException {
        return get(userId, 10);
    }

    /**
     * Retrieve items similar to the given item.
     */
    public List<Recommendation> similar(String itemId, int limit)
            throws IOException, InterruptedException {

        String path = "/api/recommendations/similar/" + itemId + "?limit=" + limit;
        String json = http.get(path);
        Map<String, Object> response = http.mapper.readValue(
                json, new TypeReference<Map<String, Object>>() {});
        List<?> rawList = (List<?>) response.getOrDefault("recommendations", List.of());
        String listJson = http.mapper.writeValueAsString(rawList);
        return http.mapper.readValue(listJson, new TypeReference<List<Recommendation>>() {});
    }

    public List<Recommendation> similar(String itemId)
            throws IOException, InterruptedException {
        return similar(itemId, 10);
    }

    /**
     * Retrieve globally popular items, optionally filtered by category.
     */
    public List<Recommendation> popular(int limit, String category)
            throws IOException, InterruptedException {

        String path = "/api/recommendations/popular?limit=" + limit;
        if (category != null && !category.isBlank()) {
            path += "&category=" + java.net.URLEncoder.encode(category, java.nio.charset.StandardCharsets.UTF_8);
        }
        String json = http.get(path);
        Map<String, Object> response = http.mapper.readValue(
                json, new TypeReference<Map<String, Object>>() {});
        List<?> rawList = (List<?>) response.getOrDefault("recommendations", List.of());
        String listJson = http.mapper.writeValueAsString(rawList);
        return http.mapper.readValue(listJson, new TypeReference<List<Recommendation>>() {});
    }

    public List<Recommendation> popular(int limit) throws IOException, InterruptedException {
        return popular(limit, null);
    }
}
