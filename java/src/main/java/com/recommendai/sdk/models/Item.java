package com.recommendai.sdk.models;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.Map;

/**
 * A catalogue item in the RecSys.AI system.
 */
public class Item {

    @JsonProperty("item_id")
    private String itemId;

    @JsonProperty("properties")
    private Map<String, Object> properties;

    @JsonProperty("created_at")
    private Instant createdAt;

    @JsonProperty("updated_at")
    private Instant updatedAt;

    public Item() {}

    public String getItemId()                  { return itemId; }
    public Map<String, Object> getProperties() { return properties; }
    public Instant getCreatedAt()              { return createdAt; }
    public Instant getUpdatedAt()              { return updatedAt; }

    @Override
    public String toString() {
        return "Item{itemId='" + itemId + "', properties=" + properties + "}";
    }
}
