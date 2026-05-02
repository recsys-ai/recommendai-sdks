package com.recommendai.sdk.models;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.Map;

/**
 * A recorded user–item interaction in the RecSys.AI system.
 */
public class Interaction {

    @JsonProperty("interaction_id")
    private String interactionId;

    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("item_id")
    private String itemId;

    @JsonProperty("interaction_type")
    private String interactionType;

    @JsonProperty("value")
    private Double value;

    @JsonProperty("timestamp")
    private Instant timestamp;

    @JsonProperty("metadata")
    private Map<String, Object> metadata;

    public Interaction() {}

    public String getInteractionId()            { return interactionId; }
    public String getUserId()                   { return userId; }
    public String getItemId()                   { return itemId; }
    public String getInteractionType()          { return interactionType; }
    public Double getValue()                    { return value; }
    public Instant getTimestamp()               { return timestamp; }
    public Map<String, Object> getMetadata()    { return metadata; }

    @Override
    public String toString() {
        return "Interaction{id='" + interactionId + "', userId='" + userId
               + "', itemId='" + itemId + "', type='" + interactionType + "'}";
    }
}
