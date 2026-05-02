package com.recommendai.sdk.exceptions;

/** Thrown when the API returns HTTP 401 Unauthorized. */
public class AuthenticationException extends RecommendAIException {
    public AuthenticationException(String message) { super(message, 401); }
}
