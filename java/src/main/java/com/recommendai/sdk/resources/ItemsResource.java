package com.recommendai.sdk.resources;

import com.recommendai.sdk.ApiHttpClient;
import com.recommendai.sdk.models.Item;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Provides access to the {@code /api/items} endpoints.
 */
public class ItemsResource {

    private final ApiHttpClient http;

    public ItemsResource(ApiHttpClient http) {
        this.http = http;
    }

    /**
     * Create a new catalogue item.
     *
     * @param itemId     unique identifier for the item
     * @param properties arbitrary key-value properties (may be {@code null})
     */
    public Item create(String itemId, Map<String, Object> properties)
            throws IOException, InterruptedException {

        Map<String, Object> body = new HashMap<>();
        body.put("item_id",    itemId);
        body.put("properties", properties != null ? properties : Map.of());
        String json = http.post("/api/items", body);
        return http.mapper.readValue(json, Item.class);
    }

    /** Create an item with no additional properties. */
    public Item create(String itemId) throws IOException, InterruptedException {
        return create(itemId, null);
    }

    /**
     * Retrieve an item by ID.
     *
     * @throws com.recommendai.sdk.exceptions.NotFoundException if the item does not exist
     */
    public Item get(String itemId) throws IOException, InterruptedException {
        String json = http.get("/api/items/" + itemId);
        return http.mapper.readValue(json, Item.class);
    }

    /**
     * Update an item's properties.
     *
     * @param itemId     the item to update
     * @param properties replacement properties map
     */
    public Item update(String itemId, Map<String, Object> properties)
            throws IOException, InterruptedException {

        Map<String, Object> body = Map.of("properties", properties != null ? properties : Map.of());
        String json = http.put("/api/items/" + itemId, body);
        return http.mapper.readValue(json, Item.class);
    }

    /**
     * Delete an item permanently.
     *
     * @throws com.recommendai.sdk.exceptions.NotFoundException if the item does not exist
     */
    public void delete(String itemId) throws IOException, InterruptedException {
        http.delete("/api/items/" + itemId);
    }

    /**
     * Bulk create or update items.
     *
     * @param items list of item maps, each with {@code item_id} and optional {@code properties}
     * @return list of upserted {@link Item} objects
     */
    public List<Item> upsert(List<Map<String, Object>> items)
            throws IOException, InterruptedException {

        Map<String, Object> body = Map.of("items", items);
        String json = http.post("/api/items/bulk", body);
        Map<String, Object> response = http.mapper.readValue(
                json, new com.fasterxml.jackson.core.type.TypeReference<Map<String, Object>>() {});
        List<?> rawList = (List<?>) response.getOrDefault("items", List.of());
        String listJson = http.mapper.writeValueAsString(rawList);
        return http.mapper.readValue(listJson, new com.fasterxml.jackson.core.type.TypeReference<List<Item>>() {});
    }
}
