package com.recommendai.sdk.exceptions;

/**
 * Base exception for all RecSys.AI SDK errors.
 */
public class RecommendAIException extends RuntimeException {

    private final int statusCode;

    public RecommendAIException(String message) {
        this(message, 0);
    }

    public RecommendAIException(String message, int statusCode) {
        super(message);
        this.statusCode = statusCode;
    }

    public RecommendAIException(String message, int statusCode, Throwable cause) {
        super(message, cause);
        this.statusCode = statusCode;
    }

    /** HTTP status code returned by the API, or {@code 0} if not applicable. */
    public int getStatusCode() { return statusCode; }
}
