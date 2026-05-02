package com.recommendai.sdk.resources;

import com.recommendai.sdk.ApiHttpClient;
import com.recommendai.sdk.models.Interaction;
import com.recommendai.sdk.models.InteractionType;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Provides access to the {@code /api/interactions} endpoints.
 */
public class InteractionsResource {

    private final ApiHttpClient http;

    public InteractionsResource(ApiHttpClient http) {
        this.http = http;
    }

    /**
     * Record a user–item interaction.
     *
     * @param userId          the user performing the interaction
     * @param itemId          the item being interacted with
     * @param interactionType the type of interaction
     * @param value           optional numeric value (e.g. a rating 1-10); may be {@code null}
     * @param metadata        optional extra properties; may be {@code null}
     */
    public Interaction create(
            String userId,
            String itemId,
            InteractionType interactionType,
            Double value,
            Map<String, Object> metadata) throws IOException, InterruptedException {

        Map<String, Object> body = new HashMap<>();
        body.put("user_id",          userId);
        body.put("item_id",          itemId);
        body.put("interaction_type", interactionType.getValue());
        if (value    != null) body.put("value",    value);
        if (metadata != null) body.put("metadata", metadata);

        String json = http.post("/api/interactions", body);
        return http.mapper.readValue(json, Interaction.class);
    }

    /**
     * Record a user–item interaction without a numeric value or metadata.
     */
    public Interaction create(String userId, String itemId, InteractionType interactionType)
            throws IOException, InterruptedException {
        return create(userId, itemId, interactionType, null, null);
    }

    /**
     * Record an interaction with a numeric value but no metadata.
     */
    public Interaction create(
            String userId,
            String itemId,
            InteractionType interactionType,
            Double value) throws IOException, InterruptedException {
        return create(userId, itemId, interactionType, value, null);
    }
}
