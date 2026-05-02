package com.recommendai.sdk;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.recommendai.sdk.exceptions.*;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * Internal HTTP wrapper that handles authentication headers, JSON
 * serialisation, and maps HTTP error codes to typed exceptions.
 */
public class ApiHttpClient {

    private final String baseUrl;
    private final HttpClient http;
    public final ObjectMapper mapper;

    public ApiHttpClient(String baseUrl, String apiKey, Duration timeout) {
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        this.http = HttpClient.newBuilder()
                .connectTimeout(timeout)
                .build();
        this.mapper = new ObjectMapper()
                .registerModule(new JavaTimeModule())
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        this._apiKey  = apiKey;
        this._timeout = timeout;
    }

    private final String   _apiKey;
    private final Duration _timeout;

    // ── Low-level helpers ─────────────────────────────────────────────────────

    private HttpRequest.Builder baseRequest(String path) {
        return HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + path))
                .timeout(_timeout)
                .header("Authorization", "Bearer " + _apiKey)
                .header("User-Agent",    "recommendai-java/1.0.0")
                .header("Content-Type",  "application/json");
    }

    public String get(String path) throws IOException, InterruptedException {
        HttpRequest req = baseRequest(path).GET().build();
        return execute(req);
    }

    public String post(String path, Object body) throws IOException, InterruptedException {
        String json = mapper.writeValueAsString(body);
        HttpRequest req = baseRequest(path)
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();
        return execute(req);
    }

    public String put(String path, Object body) throws IOException, InterruptedException {
        String json = mapper.writeValueAsString(body);
        HttpRequest req = baseRequest(path)
                .PUT(HttpRequest.BodyPublishers.ofString(json))
                .build();
        return execute(req);
    }

    public void delete(String path) throws IOException, InterruptedException {
        HttpRequest req = baseRequest(path).DELETE().build();
        execute(req);
    }

    // ── Response handling ─────────────────────────────────────────────────────

    private String execute(HttpRequest req) throws IOException, InterruptedException {
        HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
        int status = res.statusCode();

        if (status == 204) return "{}"; // DELETE success

        if (status >= 200 && status < 300) return res.body();

        // Parse error detail from response body when available
        String detail = extractDetail(res.body(), status);
        switch (status) {
            case 401: throw new AuthenticationException(detail);
            case 404: throw new NotFoundException(detail);
            case 400:
            case 422: throw new ValidationException(detail, status);
            case 429: throw new RateLimitException(detail);
            default:
                if (status >= 500) throw new ServerException(detail, status);
                throw new RecommendAIException(detail, status);
        }
    }

    private String extractDetail(String body, int status) {
        try {
            JsonNode node = mapper.readTree(body);
            if (node.has("detail")) return node.get("detail").asText();
        } catch (Exception ignored) {}
        return "HTTP " + status;
    }
}
