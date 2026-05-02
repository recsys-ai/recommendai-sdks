package com.recommendai.sdk;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.recommendai.sdk.exceptions.AuthenticationException;
import com.recommendai.sdk.exceptions.NotFoundException;
import com.recommendai.sdk.exceptions.RateLimitException;
import com.recommendai.sdk.models.Item;
import com.recommendai.sdk.models.Recommendation;
import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import okhttp3.mockwebserver.RecordedRequest;
import org.junit.jupiter.api.*;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@TestMethodOrder(MethodOrderer.MethodName.class)
class RecommendAIClientTest {

    private static MockWebServer server;
    private static RecommendAIClient client;
    private static final ObjectMapper mapper = new ObjectMapper();

    @BeforeAll
    static void startServer() throws Exception {
        server = new MockWebServer();
        server.start();
        client = new RecommendAIClient("test-key", server.url("/").toString().replaceAll("/$", ""));
    }

    @AfterAll
    static void stopServer() throws Exception {
        server.shutdown();
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private void enqueue(int status, Object body) throws Exception {
        server.enqueue(new MockResponse()
                .setResponseCode(status)
                .setHeader("Content-Type", "application/json")
                .setBody(mapper.writeValueAsString(body)));
    }

    // ── ping ─────────────────────────────────────────────────────────────────

    @Test
    void ping_returnsTrueWhen200() throws Exception {
        server.enqueue(new MockResponse().setResponseCode(200));
        assertTrue(client.ping());
        RecordedRequest req = server.takeRequest();
        assertEquals("/health", req.getPath());
    }

    @Test
    void ping_returnsFalseWhen503() throws Exception {
        server.enqueue(new MockResponse().setResponseCode(503));
        assertFalse(client.ping());
        server.takeRequest();
    }

    // ── recommendations ───────────────────────────────────────────────────────

    @Test
    void recommendations_get_returnsItems() throws Exception {
        enqueue(200, Map.of("recommendations", List.of(
                Map.of("item_id", "item1", "score", 0.9, "reason", "test", "metadata", Map.of())
        )));

        List<Recommendation> recs = client.recommendations().get("user1", 5);
        assertEquals(1, recs.size());
        assertEquals("item1", recs.get(0).getItemId());

        RecordedRequest req = server.takeRequest();
        assertTrue(req.getPath().contains("/api/recommendations"));
        assertTrue(req.getPath().contains("user_id=user1"));
    }

    @Test
    void recommendations_similar_callsCorrectPath() throws Exception {
        enqueue(200, Map.of("recommendations", List.of(
                Map.of("item_id", "item2", "score", 0.8, "reason", "", "metadata", Map.of())
        )));

        List<Recommendation> recs = client.recommendations().similar("item99", 10);
        assertEquals(1, recs.size());
        assertEquals("item2", recs.get(0).getItemId());

        RecordedRequest req = server.takeRequest();
        assertTrue(req.getPath().contains("/api/recommendations/similar/item99"));
    }

    @Test
    void recommendations_popular_passesCategoryParam() throws Exception {
        enqueue(200, Map.of("recommendations", List.of(
                Map.of("item_id", "book1", "score", 0.7, "reason", "", "metadata", Map.of())
        )));

        List<Recommendation> recs = client.recommendations().popular(5, "books");
        assertEquals(1, recs.size());

        RecordedRequest req = server.takeRequest();
        assertTrue(req.getPath().contains("category=books"));
    }

    // ── items ─────────────────────────────────────────────────────────────────

    @Test
    void items_upsert_postsToBulkEndpoint() throws Exception {
        enqueue(200, Map.of("items", List.of(
                Map.of("item_id", "itemA", "properties", Map.of(), "created_at", "", "updated_at", "")
        )));

        List<Item> items = client.items().upsert(List.of(
                Map.of("item_id", "itemA", "properties", Map.of("name", "Book A"))
        ));
        assertEquals(1, items.size());
        assertEquals("itemA", items.get(0).getItemId());

        RecordedRequest req = server.takeRequest();
        assertEquals("POST", req.getMethod());
        assertTrue(req.getPath().contains("/api/items/bulk"));
    }

    // ── error handling ────────────────────────────────────────────────────────

    @Test
    void authenticationError_thrownOn401() throws Exception {
        enqueue(401, Map.of("detail", "invalid api key"));
        assertThrows(AuthenticationException.class,
                () -> client.recommendations().get("u", 5));
        server.takeRequest();
    }

    @Test
    void notFoundError_thrownOn404() throws Exception {
        enqueue(404, Map.of("detail", "not found"));
        assertThrows(NotFoundException.class,
                () -> client.recommendations().get("u", 5));
        server.takeRequest();
    }

    @Test
    void rateLimitError_thrownOn429() throws Exception {
        enqueue(429, Map.of("detail", "rate limit exceeded"));
        assertThrows(RateLimitException.class,
                () -> client.recommendations().get("u", 5));
        server.takeRequest();
    }
}
