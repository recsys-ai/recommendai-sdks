package com.recommendai.sdk

import com.fasterxml.jackson.module.kotlin.readValue

// ── RecommendationsResource ───────────────────────────────────────────────────

class RecommendationsResource(private val client: RecommendAIClient) {
    fun get(userId: String, limit: Int = 10): List<Recommendation> {
        val url  = "${client.baseUrl}/api/recommendations?user_id=${userId}&limit=${limit}"
        val req  = client.requestBuilder(url).get().build()
        val resp = client.execute(req)
        val raw  = mapper.readValue<Map<String, Any>>(resp.body!!.string())
        @Suppress("UNCHECKED_CAST")
        val list = raw["recommendations"] as? List<Map<String, Any?>> ?: emptyList()
        return list.map { m ->
            Recommendation(
                itemId   = m["item_id"].toString(),
                score    = (m["score"] as? Number)?.toDouble() ?: 0.0,
                reason   = m["reason"]?.toString() ?: "",
                metadata = @Suppress("UNCHECKED_CAST")(m["metadata"] as? Map<String, Any?>) ?: emptyMap(),
            )
        }
    }

    fun similar(itemId: String, limit: Int = 10): List<Recommendation> {
        val url  = "${client.baseUrl}/api/recommendations/similar/${itemId}?limit=${limit}"
        val req  = client.requestBuilder(url).get().build()
        val resp = client.execute(req)
        val raw  = mapper.readValue<Map<String, Any>>(resp.body!!.string())
        @Suppress("UNCHECKED_CAST")
        val list = raw["recommendations"] as? List<Map<String, Any?>> ?: emptyList()
        return list.map { m ->
            Recommendation(
                itemId   = m["item_id"].toString(),
                score    = (m["score"] as? Number)?.toDouble() ?: 0.0,
                reason   = m["reason"]?.toString() ?: "",
                metadata = @Suppress("UNCHECKED_CAST")(m["metadata"] as? Map<String, Any?>) ?: emptyMap(),
            )
        }
    }

    fun popular(limit: Int = 10, category: String? = null): List<Recommendation> {
        var url = "${client.baseUrl}/api/recommendations/popular?limit=${limit}"
        if (category != null) {
            val enc = java.net.URLEncoder.encode(category, "UTF-8")
            url += "&category=$enc"
        }
        val req  = client.requestBuilder(url).get().build()
        val resp = client.execute(req)
        val raw  = mapper.readValue<Map<String, Any>>(resp.body!!.string())
        @Suppress("UNCHECKED_CAST")
        val list = raw["recommendations"] as? List<Map<String, Any?>> ?: emptyList()
        return list.map { m ->
            Recommendation(
                itemId   = m["item_id"].toString(),
                score    = (m["score"] as? Number)?.toDouble() ?: 0.0,
                reason   = m["reason"]?.toString() ?: "",
                metadata = @Suppress("UNCHECKED_CAST")(m["metadata"] as? Map<String, Any?>) ?: emptyMap(),
            )
        }
    }
}

// ── UsersResource ─────────────────────────────────────────────────────────────

class UsersResource(private val client: RecommendAIClient) {

    fun create(userId: String, properties: Map<String, Any?> = emptyMap()): User {
        val url  = "${client.baseUrl}/api/users"
        val body = mapOf("user_id" to userId, "properties" to properties)
        val req  = client.requestBuilder(url).post(client.toJson(body)).build()
        return parseUser(client.execute(req).body!!.string())
    }

    fun get(userId: String): User {
        val url = "${client.baseUrl}/api/users/${userId}"
        val req = client.requestBuilder(url).get().build()
        return parseUser(client.execute(req).body!!.string())
    }

    fun update(userId: String, properties: Map<String, Any?>): User {
        val url  = "${client.baseUrl}/api/users/${userId}"
        val body = mapOf("properties" to properties)
        val req  = client.requestBuilder(url).put(client.toJson(body)).build()
        return parseUser(client.execute(req).body!!.string())
    }

    fun delete(userId: String) {
        val url = "${client.baseUrl}/api/users/${userId}"
        val req = client.requestBuilder(url).delete().build()
        client.execute(req)
    }

    private fun parseUser(json: String): User {
        val m = mapper.readValue<Map<String, Any?>>(json)
        @Suppress("UNCHECKED_CAST")
        return User(
            userId     = m["user_id"].toString(),
            properties = (m["properties"] as? Map<String, Any?>) ?: emptyMap(),
            createdAt  = m["created_at"]?.toString(),
            updatedAt  = m["updated_at"]?.toString(),
        )
    }
}

// ── ItemsResource ─────────────────────────────────────────────────────────────

class ItemsResource(private val client: RecommendAIClient) {

    fun create(itemId: String, properties: Map<String, Any?> = emptyMap()): Item {
        val url  = "${client.baseUrl}/api/items"
        val body = mapOf("item_id" to itemId, "properties" to properties)
        val req  = client.requestBuilder(url).post(client.toJson(body)).build()
        return parseItem(client.execute(req).body!!.string())
    }

    fun get(itemId: String): Item {
        val url = "${client.baseUrl}/api/items/${itemId}"
        val req = client.requestBuilder(url).get().build()
        return parseItem(client.execute(req).body!!.string())
    }

    fun update(itemId: String, properties: Map<String, Any?>): Item {
        val url  = "${client.baseUrl}/api/items/${itemId}"
        val body = mapOf("properties" to properties)
        val req  = client.requestBuilder(url).put(client.toJson(body)).build()
        return parseItem(client.execute(req).body!!.string())
    }

    fun delete(itemId: String) {
        val url = "${client.baseUrl}/api/items/${itemId}"
        val req = client.requestBuilder(url).delete().build()
        client.execute(req)
    }

    fun upsert(items: List<Map<String, Any?>>): List<Item> {
        val url  = "${client.baseUrl}/api/items/bulk"
        val body = mapOf("items" to items)
        val req  = client.requestBuilder(url).post(client.toJson(body)).build()
        val resp = client.execute(req)
        val raw  = mapper.readValue<Map<String, Any>>(resp.body!!.string())
        @Suppress("UNCHECKED_CAST")
        val list = raw["items"] as? List<Map<String, Any?>> ?: emptyList()
        return list.map { m ->
            Item(
                itemId     = m["item_id"].toString(),
                properties = @Suppress("UNCHECKED_CAST")(m["properties"] as? Map<String, Any?>) ?: emptyMap(),
                createdAt  = m["created_at"]?.toString(),
                updatedAt  = m["updated_at"]?.toString(),
            )
        }
    }

    private fun parseItem(json: String): Item {
        val m = mapper.readValue<Map<String, Any?>>(json)
        @Suppress("UNCHECKED_CAST")
        return Item(
            itemId     = m["item_id"].toString(),
            properties = (m["properties"] as? Map<String, Any?>) ?: emptyMap(),
            createdAt  = m["created_at"]?.toString(),
            updatedAt  = m["updated_at"]?.toString(),
        )
    }
}

// ── InteractionsResource ──────────────────────────────────────────────────────

class InteractionsResource(private val client: RecommendAIClient) {

    fun create(
        userId:          String,
        itemId:          String,
        interactionType: InteractionType,
        value:           Double? = null,
        metadata:        Map<String, Any?>? = null,
    ): Interaction {
        val url = "${client.baseUrl}/api/interactions"
        val body = mutableMapOf<String, Any?>(
            "user_id"          to userId,
            "item_id"          to itemId,
            "interaction_type" to interactionType.name,
        )
        if (value    != null) body["value"]    = value
        if (metadata != null) body["metadata"] = metadata
        val req  = client.requestBuilder(url).post(client.toJson(body)).build()
        val m    = mapper.readValue<Map<String, Any?>>(client.execute(req).body!!.string())
        @Suppress("UNCHECKED_CAST")
        return Interaction(
            interactionId   = m["interaction_id"]?.toString()   ?: "",
            userId          = m["user_id"]?.toString()          ?: userId,
            itemId          = m["item_id"]?.toString()          ?: itemId,
            interactionType = m["interaction_type"]?.toString() ?: interactionType.name,
            value           = (m["value"] as? Number)?.toDouble(),
            metadata        = (m["metadata"] as? Map<String, Any?>) ?: emptyMap(),
            timestamp       = m["timestamp"]?.toString(),
        )
    }
}
