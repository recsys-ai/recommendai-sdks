package com.recommendai.sdk.models;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.Map;

/**
 * A single recommendation returned by the RecSys.AI API.
 */
public class Recommendation {

    @JsonProperty("item_id")
    private String itemId;

    @JsonProperty("score")
    private double score;

    @JsonProperty("reason")
    private String reason;

    @JsonProperty("metadata")
    private Map<String, Object> metadata;

    // Required by Jackson
    public Recommendation() {}

    public Recommendation(String itemId, double score, String reason, Map<String, Object> metadata) {
        this.itemId    = itemId;
        this.score     = score;
        this.reason    = reason;
        this.metadata  = metadata;
    }

    public String getItemId()                  { return itemId; }
    public double getScore()                   { return score; }
    public String getReason()                  { return reason; }
    public Map<String, Object> getMetadata()   { return metadata; }

    @Override
    public String toString() {
        return "Recommendation{itemId='" + itemId + "', score=" + score
               + ", reason='" + reason + "'}";
    }
}
