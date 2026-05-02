package com.recommendai.sdk.exceptions;

/** Thrown when the API returns HTTP 400 / 422 Validation Error. */
public class ValidationException extends RecommendAIException {
    public ValidationException(String message) { super(message, 400); }
    public ValidationException(String message, int status) { super(message, status); }
}
