package com.recommendai.sdk

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.*
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@TestMethodOrder(MethodOrderer.MethodName::class)
class RecommendAIClientTest {

    private val json = jacksonObjectMapper()

    private lateinit var server: MockWebServer
    private lateinit var client: RecommendAIClient

    @BeforeEach
    fun setup() {
        server = MockWebServer()
        server.start()
        client = RecommendAIClient(
            apiKey = "test-key",
            config = ClientConfig(baseUrl = server.url("/").toString().trimEnd('/'))
        )
    }

    @AfterEach
    fun teardown() {
        server.shutdown()
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private fun enqueue(status: Int, body: Any) {
        server.enqueue(
            MockResponse()
                .setResponseCode(status)
                .setHeader("Content-Type", "application/json")
                .setBody(json.writeValueAsString(body))
        )
    }

    // ── ping ─────────────────────────────────────────────────────────────────

    @Test
    fun `ping returns true when server responds 200`() {
        server.enqueue(MockResponse().setResponseCode(200))
        assertTrue(client.ping())
        val req = server.takeRequest()
        assertEquals("/health", req.path)
    }

    @Test
    fun `ping returns false when server responds 503`() {
        server.enqueue(MockResponse().setResponseCode(503))
        assertFalse(client.ping())
    }

    // ── recommendations ───────────────────────────────────────────────────────

    @Test
    fun `recommendations get returns items`() {
        enqueue(200, mapOf("recommendations" to listOf(
            mapOf("item_id" to "item1", "score" to 0.9, "reason" to "test", "metadata" to emptyMap<String, Any>())
        )))

        val recs = client.recommendations.get("user1", 5)
        assertEquals(1, recs.size)
        assertEquals("item1", recs[0].itemId)

        val req = server.takeRequest()
        assertTrue(req.path!!.contains("/api/recommendations"))
        assertTrue(req.path!!.contains("user_id=user1"))
    }

    @Test
    fun `recommendations similar calls correct path`() {
        enqueue(200, mapOf("recommendations" to listOf(
            mapOf("item_id" to "item2", "score" to 0.8, "reason" to "", "metadata" to emptyMap<String, Any>())
        )))

        val recs = client.recommendations.similar("item99", 10)
        assertEquals(1, recs.size)
        assertEquals("item2", recs[0].itemId)

        val req = server.takeRequest()
        assertTrue(req.path!!.contains("/api/recommendations/similar/item99"))
    }

    @Test
    fun `recommendations popular passes category param`() {
        enqueue(200, mapOf("recommendations" to listOf(
            mapOf("item_id" to "book1", "score" to 0.7, "reason" to "", "metadata" to emptyMap<String, Any>())
        )))

        val recs = client.recommendations.popular(5, "books")
        assertEquals(1, recs.size)

        val req = server.takeRequest()
        assertTrue(req.path!!.contains("category=books"))
    }

    // ── items ─────────────────────────────────────────────────────────────────

    @Test
    fun `items upsert posts to bulk endpoint`() {
        enqueue(200, mapOf("items" to listOf(
            mapOf("item_id" to "itemA", "properties" to emptyMap<String, Any>(), "created_at" to null, "updated_at" to null)
        )))

        val items = client.items.upsert(listOf(
            mapOf("item_id" to "itemA", "properties" to mapOf("name" to "Book A"))
        ))
        assertEquals(1, items.size)
        assertEquals("itemA", items[0].itemId)

        val req = server.takeRequest()
        assertEquals("POST", req.method)
        assertTrue(req.path!!.contains("/api/items/bulk"))
    }

    // ── error handling ────────────────────────────────────────────────────────

    @Test
    fun `401 response throws AuthenticationError`() {
        enqueue(401, mapOf("detail" to "invalid api key"))
        assertThrows<AuthenticationException> {
            client.recommendations.get("u", 5)
        }
        server.takeRequest()
    }

    @Test
    fun `404 response throws NotFoundError`() {
        enqueue(404, mapOf("detail" to "not found"))
        assertThrows<NotFoundException> {
            client.recommendations.get("u", 5)
        }
        server.takeRequest()
    }

    @Test
    fun `429 response throws RateLimitError`() {
        enqueue(429, mapOf("detail" to "rate limit exceeded"))
        assertThrows<RateLimitException> {
            client.recommendations.get("u", 5)
        }
        server.takeRequest()
    }
}
