package com.recommendai.sdk.resources;

import com.recommendai.sdk.ApiHttpClient;
import com.recommendai.sdk.models.User;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Provides access to the {@code /api/users} endpoints.
 */
public class UsersResource {

    private final ApiHttpClient http;

    public UsersResource(ApiHttpClient http) {
        this.http = http;
    }

    /**
     * Create a new user.
     *
     * @param userId     unique identifier for the user
     * @param properties arbitrary key-value properties (may be {@code null})
     */
    public User create(String userId, Map<String, Object> properties)
            throws IOException, InterruptedException {

        Map<String, Object> body = new HashMap<>();
        body.put("user_id",     userId);
        body.put("properties",  properties != null ? properties : Map.of());
        String json = http.post("/api/users", body);
        return http.mapper.readValue(json, User.class);
    }

    /** Create a user with no additional properties. */
    public User create(String userId) throws IOException, InterruptedException {
        return create(userId, null);
    }

    /**
     * Retrieve a user by ID.
     *
     * @throws com.recommendai.sdk.exceptions.NotFoundException if the user does not exist
     */
    public User get(String userId) throws IOException, InterruptedException {
        String json = http.get("/api/users/" + userId);
        return http.mapper.readValue(json, User.class);
    }

    /**
     * Update a user's properties.
     *
     * @param userId     the user to update
     * @param properties replacement properties map
     */
    public User update(String userId, Map<String, Object> properties)
            throws IOException, InterruptedException {

        Map<String, Object> body = Map.of("properties", properties != null ? properties : Map.of());
        String json = http.put("/api/users/" + userId, body);
        return http.mapper.readValue(json, User.class);
    }

    /**
     * Delete a user permanently.
     *
     * @throws com.recommendai.sdk.exceptions.NotFoundException if the user does not exist
     */
    public void delete(String userId) throws IOException, InterruptedException {
        http.delete("/api/users/" + userId);
    }
}
