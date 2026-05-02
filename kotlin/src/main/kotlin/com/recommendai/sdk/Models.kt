package com.recommendai.sdk

/** Interaction types supported by the platform. */
enum class InteractionType {
    view, like, dislike, purchase, rating, share, bookmark;
}

data class Recommendation(
    val itemId:   String,
    val score:    Double,
    val reason:   String,
    val metadata: Map<String, Any?> = emptyMap(),
)

data class User(
    val userId:     String,
    val properties: Map<String, Any?> = emptyMap(),
    val createdAt:  String? = null,
    val updatedAt:  String? = null,
)

data class Item(
    val itemId:     String,
    val properties: Map<String, Any?> = emptyMap(),
    val createdAt:  String? = null,
    val updatedAt:  String? = null,
)

data class Interaction(
    val interactionId:   String,
    val userId:          String,
    val itemId:          String,
    val interactionType: String,
    val value:           Double? = null,
    val metadata:        Map<String, Any?> = emptyMap(),
    val timestamp:       String? = null,
)
