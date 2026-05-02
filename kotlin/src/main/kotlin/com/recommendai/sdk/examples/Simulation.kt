package com.recommendai.sdk.examples

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.recommendai.sdk.*
import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

private val json = jacksonObjectMapper()
private const val MOCK_PORT = 17898

// ── djb2 hash ─────────────────────────────────────────────────────────────────

private fun djb2(s: String): Long {
    var h = 5381L
    for (c in s) h = (h shl 5) + h + c.code.toLong()
    return h and 0xFFFFFFFFL
}

// ── Mock server state ─────────────────────────────────────────────────────────

private val users:        ConcurrentHashMap<String, MutableMap<String, Any?>> = ConcurrentHashMap()
private val items:        ConcurrentHashMap<String, MutableMap<String, Any?>> = ConcurrentHashMap()
private val interactions: MutableList<Map<String, Any?>> = java.util.Collections.synchronizedList(mutableListOf())

private fun computeRecs(userId: String, limit: Int): List<Map<String, Any?>> {
    val seen = interactions
        .filter { it["user_id"] == userId }
        .map { it["item_id"].toString() }
        .toSet()

    val preferredGenre = (users[userId]?.get("properties") as? Map<*, *>)
        ?.get("preferred_genre")?.toString() ?: ""

    return items.entries
        .filter { it.key !in seen }
        .map { (itemId, item) ->
            val props  = item["properties"] as? Map<*, *> ?: emptyMap<Any, Any>()
            val rating = (props["rating"] as? Number)?.toDouble() ?: 0.0
            val genre  = props["genre"]?.toString() ?: ""
            var score  = rating / 10.0
            if (preferredGenre.isNotEmpty() && genre == preferredGenre) score += 0.2
            val hashPart = djb2("$userId$itemId") % 100
            score = minOf(score + hashPart / 1000.0, 1.0)
            score = (score * 10000).toLong() / 10000.0
            val reason = if (preferredGenre.isNotEmpty() && genre == preferredGenre)
                "Matches preferred genre: $preferredGenre" else "Highly rated content"
            mapOf(
                "item_id"  to itemId,
                "score"    to score,
                "reason"   to reason,
                "metadata" to mapOf("title" to props["title"]),
            )
        }
        .sortedByDescending { (it["score"] as? Number)?.toDouble() ?: 0.0 }
        .take(limit)
}

// ── Route handling ─────────────────────────────────────────────────────────────

private fun HttpExchange.body(): Map<String, Any?> = runCatching {
    @Suppress("UNCHECKED_CAST")
    json.readValue(requestBody.readBytes(), Map::class.java) as Map<String, Any?>
}.getOrDefault(emptyMap())

private fun HttpExchange.respond(status: Int, data: Any?) {
    val bytes = json.writeValueAsBytes(data)
    responseHeaders.set("Content-Type", "application/json")
    sendResponseHeaders(status, if (status == 204) -1L else bytes.size.toLong())
    if (status != 204) responseBody.use { it.write(bytes) }
}

private fun HttpExchange.queryParams(): Map<String, String> =
    (requestURI.query ?: "").split("&").mapNotNull {
        val (k, v) = it.split("=", limit = 2).let { p -> (p.getOrNull(0) ?: "") to (p.getOrNull(1) ?: "") }
        if (k.isNotEmpty()) k to v else null
    }.toMap()

private fun startMockServer() {
    val server = HttpServer.create(InetSocketAddress(MOCK_PORT), 0)
    server.executor = Executors.newCachedThreadPool()

    // POST /api/users
    server.createContext("/api/users") { ex ->
        val parts = ex.requestURI.path.trimEnd('/').split("/")
        val method = ex.requestMethod
        when {
            method == "POST" && parts.last() == "users" -> {
                val b = ex.body()
                val uid = b["user_id"].toString()
                val rec = mutableMapOf<String, Any?>(
                    "user_id" to uid, "properties" to b["properties"],
                    "created_at" to "2024-01-01T00:00:00Z", "updated_at" to "2024-01-01T00:00:00Z"
                )
                users[uid] = rec; ex.respond(201, rec)
            }
            method == "GET" && parts.size == 3 -> {
                val uid = parts.last()
                val u = users[uid]; if (u != null) ex.respond(200, u)
                else ex.respond(404, mapOf("detail" to "User not found: $uid"))
            }
            method == "PUT" && parts.size == 3 -> {
                val uid = parts.last(); val b = ex.body()
                val u = users[uid]
                if (u != null) { u["properties"] = b["properties"]; u["updated_at"] = "2024-01-01T00:00:00Z"; ex.respond(200, u) }
                else ex.respond(404, mapOf("detail" to "User not found: $uid"))
            }
            method == "DELETE" && parts.size == 3 -> {
                val uid = parts.last()
                if (users.remove(uid) != null) ex.respond(204, null)
                else ex.respond(404, mapOf("detail" to "User not found: $uid"))
            }
            else -> ex.respond(404, mapOf("detail" to "Not found"))
        }
    }

    // Items
    server.createContext("/api/items") { ex ->
        val parts = ex.requestURI.path.trimEnd('/').split("/")
        val method = ex.requestMethod
        when {
            method == "POST" && parts.last() == "items" -> {
                val b = ex.body(); val iid = b["item_id"].toString()
                val rec = mutableMapOf<String, Any?>(
                    "item_id" to iid, "properties" to b["properties"],
                    "created_at" to "2024-01-01T00:00:00Z", "updated_at" to "2024-01-01T00:00:00Z"
                )
                items[iid] = rec; ex.respond(201, rec)
            }
            method == "GET" && parts.size == 3 -> {
                val iid = parts.last(); val i = items[iid]
                if (i != null) ex.respond(200, i) else ex.respond(404, mapOf("detail" to "Item not found: $iid"))
            }
            method == "PUT" && parts.size == 3 -> {
                val iid = parts.last(); val b = ex.body(); val i = items[iid]
                if (i != null) { i["properties"] = b["properties"]; i["updated_at"] = "2024-01-01T00:00:00Z"; ex.respond(200, i) }
                else ex.respond(404, mapOf("detail" to "Item not found: $iid"))
            }
            method == "DELETE" && parts.size == 3 -> {
                val iid = parts.last()
                if (items.remove(iid) != null) ex.respond(204, null)
                else ex.respond(404, mapOf("detail" to "Item not found: $iid"))
            }
            else -> ex.respond(404, mapOf("detail" to "Not found"))
        }
    }

    // Interactions
    server.createContext("/api/interactions") { ex ->
        val b = ex.body()
        val rec = b.toMutableMap().also {
            it["interaction_id"] = "ia_${System.nanoTime()}"
            it["timestamp"]      = "2024-01-01T00:00:00Z"
        }
        interactions.add(rec); ex.respond(201, rec)
    }

    // Recommendations
    server.createContext("/api/recommendations") { ex ->
        val params = ex.queryParams()
        val uid    = params["user_id"] ?: ""
        val limit  = params["limit"]?.toIntOrNull() ?: 10
        val recs   = computeRecs(uid, limit)
        ex.respond(200, mapOf("user_id" to uid, "recommendations" to recs))
    }

    server.start()
    println("[mock] Server listening on port $MOCK_PORT")
}

// ── Simulation ─────────────────────────────────────────────────────────────────

private fun banner(title: String) {
    val line = "=".repeat(title.length + 4)
    println("$line\n= $title =\n$line\n")
}

private fun step(n: Int, title: String) = println("── Step $n: $title")

fun main() {
    startMockServer()
    Thread.sleep(300)

    val client = RecommendAIClient(
        apiKey = "sim-api-key",
        config = ClientConfig(baseUrl = "http://127.0.0.1:$MOCK_PORT"),
    )

    // Data ──────────────────────────────────────────────────────────────────────

    data class Movie(val id: String, val title: String, val genre: String, val year: Int, val rating: Double)
    data class UserData(val id: String, val name: String, val genre: String, val age: Int)
    data class IA(val userId: String, val itemId: String, val type: InteractionType, val value: Double? = null)

    val movieList = listOf(
        Movie("movie_001", "The Matrix",               "sci-fi",   1999, 8.7),
        Movie("movie_002", "Inception",                "sci-fi",   2010, 8.8),
        Movie("movie_003", "Interstellar",             "sci-fi",   2014, 8.6),
        Movie("movie_004", "The Dark Knight",          "action",   2008, 9.0),
        Movie("movie_005", "Avengers: Endgame",        "action",   2019, 8.4),
        Movie("movie_006", "John Wick",                "action",   2014, 7.4),
        Movie("movie_007", "The Shawshank Redemption", "drama",    1994, 9.3),
        Movie("movie_008", "Forrest Gump",             "drama",    1994, 8.8),
        Movie("movie_009", "Pulp Fiction",             "thriller", 1994, 8.9),
        Movie("movie_010", "The Silence of the Lambs", "thriller", 1991, 8.6),
    )

    val userList = listOf(
        UserData("alice", "Alice Johnson", "sci-fi",   28),
        UserData("bob",   "Bob Smith",     "action",   35),
        UserData("carol", "Carol White",   "drama",    42),
        UserData("dave",  "Dave Brown",    "sci-fi",   23),
        UserData("eve",   "Eve Davis",     "thriller", 31),
    )

    val iaList = listOf(
        IA("alice", "movie_001", InteractionType.view),
        IA("alice", "movie_002", InteractionType.like),
        IA("alice", "movie_003", InteractionType.purchase),
        IA("alice", "movie_001", InteractionType.rating, 9.0),
        IA("bob",   "movie_004", InteractionType.view),
        IA("bob",   "movie_005", InteractionType.like),
        IA("bob",   "movie_006", InteractionType.purchase),
        IA("bob",   "movie_004", InteractionType.rating, 8.0),
        IA("carol", "movie_007", InteractionType.view),
        IA("carol", "movie_008", InteractionType.like),
        IA("carol", "movie_007", InteractionType.purchase),
        IA("carol", "movie_008", InteractionType.rating, 9.0),
        IA("dave",  "movie_001", InteractionType.view),
        IA("dave",  "movie_002", InteractionType.purchase),
        IA("dave",  "movie_003", InteractionType.rating, 8.5),
        IA("eve",   "movie_009", InteractionType.view),
        IA("eve",   "movie_010", InteractionType.like),
        IA("eve",   "movie_009", InteractionType.purchase),
        IA("eve",   "movie_010", InteractionType.rating, 8.0),
        IA("alice", "movie_002", InteractionType.rating, 10.0),
        IA("bob",   "movie_006", InteractionType.rating, 7.5),
        IA("carol", "movie_009", InteractionType.view),
        IA("dave",  "movie_004", InteractionType.view),
        IA("eve",   "movie_002", InteractionType.view),
        IA("alice", "movie_004", InteractionType.view),
    )

    banner("RecSys.AI Kotlin SDK — Movie Streaming Simulation")

    // Step 1: seed catalogue
    step(1, "Seeding Movie Catalogue")
    for (m in movieList) {
        val item = client.items.create(m.id, mapOf(
            "title"  to m.title, "genre" to m.genre,
            "year"   to m.year,  "rating" to m.rating,
        ))
        println("  Created item: ${item.itemId} (${item.properties["title"]})")
    }
    println("  ${movieList.size} movies added to catalogue.\n")

    // Step 2: register users
    step(2, "Registering Users")
    for (u in userList) {
        val user = client.users.create(u.id, mapOf(
            "name" to u.name, "age" to u.age, "preferred_genre" to u.genre,
        ))
        println("  Registered: ${user.userId} (${user.properties["name"]})")
    }
    println("  ${userList.size} users registered.\n")

    // Step 3: record interactions
    step(3, "Recording Watch History & Ratings")
    for (ia in iaList) {
        client.interactions.create(ia.userId, ia.itemId, ia.type, ia.value)
    }
    println("  ${iaList.size} interactions recorded.\n")

    // Step 4: recommendations
    step(4, "Getting Personalised Recommendations")
    for (u in userList) {
        val recs = client.recommendations.get(u.id, 5)
        println("  Recommendations for ${u.id}:")
        recs.forEachIndexed { i, r ->
            val title = (r.metadata["title"] ?: r.itemId).toString()
            println("    ${i + 1}. ${"%-36s".format(title)} (score: ${"%.4f".format(r.score)})  ${r.reason}")
        }
        println()
    }

    // Step 5: update item
    step(5, "Updating Item Metadata")
    val updated = client.items.update("movie_001", mapOf(
        "title" to "The Matrix", "genre" to "sci-fi",
        "year" to 1999, "rating" to 8.7, "remastered" to true,
    ))
    println("  Updated movie_001 — remastered: ${updated.properties["remastered"]}\n")

    // Step 6: update user
    step(6, "Updating User Profile")
    val alice = client.users.update("alice", mapOf(
        "name" to "Alice Johnson", "age" to 29,
        "preferred_genre" to "sci-fi", "subscription" to "premium",
    ))
    println("  alice subscription → ${alice.properties["subscription"]}\n")

    // Step 7: retrieve item
    step(7, "Verifying Item Retrieval")
    val retrieved = client.items.get("movie_004")
    println("  Retrieved: ${retrieved.itemId} — ${retrieved.properties["title"]} (${retrieved.properties["genre"]})\n")

    // Step 8: error handling
    step(8, "Error Handling Demo")
    try {
        client.users.get("ghost_999")
        println("  ERROR: expected NotFoundException was not thrown!\n")
    } catch (e: NotFoundException) {
        println("  Caught NotFoundException: ${e.message}\n")
    }

    // Step 9: cleanup
    step(9, "Cleanup")
    client.users.delete("dave")
    println("  Deleted user 'dave'.")
    try {
        client.users.get("dave")
        println("  ERROR: 'dave' should not exist!")
    } catch (e: NotFoundException) {
        println("  Confirmed: 'dave' no longer exists.")
    }

    println()
    banner("Simulation complete — all steps passed!")
}
