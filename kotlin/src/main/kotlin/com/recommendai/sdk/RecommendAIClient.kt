package com.recommendai.sdk

import com.fasterxml.jackson.databind.DeserializationFeature
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import java.util.concurrent.TimeUnit

private val JSON_MEDIA = "application/json; charset=utf-8".toMediaType()

internal val mapper = jacksonObjectMapper().apply {
    configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
}

data class ClientConfig(
    val baseUrl: String = "http://localhost:8080",
    val timeoutSeconds: Long = 30,
)

class RecommendAIClient(
    private val apiKey:  String,
    private val config:  ClientConfig = ClientConfig(),
) {
    private val http = OkHttpClient.Builder()
        .connectTimeout(config.timeoutSeconds, TimeUnit.SECONDS)
        .readTimeout(config.timeoutSeconds, TimeUnit.SECONDS)
        .build()

    val recommendations = RecommendationsResource(this)
    val users           = UsersResource(this)
    val items           = ItemsResource(this)
    val interactions    = InteractionsResource(this)

    internal val baseUrl get() = config.baseUrl

    internal fun execute(req: Request): Response {
        val resp = http.newCall(req).execute()
        if (resp.isSuccessful) return resp
        val body = runCatching { resp.body?.string() ?: "" }.getOrDefault("")
        val detail = runCatching {
            mapper.readValue<Map<String, Any>>(body)["detail"]?.toString() ?: body
        }.getOrDefault(body)
        throw when (resp.code) {
            401  -> AuthenticationException(detail)
            404  -> NotFoundException(detail)
            422  -> ValidationException(detail)
            429  -> RateLimitException(detail)
            else -> ServerException(detail, resp.code)
        }
    }

    internal fun requestBuilder(url: String): Request.Builder =
        Request.Builder()
            .url(url)
            .header("Authorization", "Bearer $apiKey")
            .header("User-Agent", "recommendai-kotlin/1.0.0")
            .header("Content-Type", "application/json")

    internal fun toJson(body: Any): okhttp3.RequestBody =
        mapper.writeValueAsString(body).toRequestBody(JSON_MEDIA)

    fun ping(): Boolean = runCatching {
        val req = requestBuilder("${baseUrl}/health").get().build()
        execute(req).use { it.isSuccessful }
    }.getOrDefault(false)
}
