package com.recommendai.sdk.exceptions;

/** Thrown when the API returns HTTP 429 Too Many Requests. */
public class RateLimitException extends RecommendAIException {
    public RateLimitException(String message) { super(message, 429); }
}
