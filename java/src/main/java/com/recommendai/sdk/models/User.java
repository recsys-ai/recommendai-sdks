package com.recommendai.sdk.models;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.Map;

/**
 * A platform user in the RecSys.AI system.
 */
public class User {

    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("properties")
    private Map<String, Object> properties;

    @JsonProperty("created_at")
    private Instant createdAt;

    @JsonProperty("updated_at")
    private Instant updatedAt;

    public User() {}

    public String getUserId()                  { return userId; }
    public Map<String, Object> getProperties() { return properties; }
    public Instant getCreatedAt()              { return createdAt; }
    public Instant getUpdatedAt()              { return updatedAt; }

    @Override
    public String toString() {
        return "User{userId='" + userId + "', properties=" + properties + "}";
    }
}
