package com.recommendai.sdk.exceptions;

/** Thrown when the API returns HTTP 5xx Server Error. */
public class ServerException extends RecommendAIException {
    public ServerException(String message) { super(message, 500); }
    public ServerException(String message, int status) { super(message, status); }
}
