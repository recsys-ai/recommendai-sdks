package com.recommendai.sdk.exceptions;

/** Thrown when the API returns HTTP 404 Not Found. */
public class NotFoundException extends RecommendAIException {
    public NotFoundException(String message) { super(message, 404); }
}
