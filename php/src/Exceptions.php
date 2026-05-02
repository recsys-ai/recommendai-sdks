<?php

declare(strict_types=1);

namespace RecommendAI;

use RuntimeException;

/**
 * Base exception for all RecSys.AI SDK errors.
 */
class RecommendAIException extends RuntimeException
{
    public function __construct(string $message, public readonly int $statusCode = 0)
    {
        parent::__construct($message);
    }
}

/**
 * Raised when the API key is invalid or missing (HTTP 401).
 */
class AuthenticationException extends RecommendAIException
{
    public function __construct(string $message = 'Authentication failed')
    {
        parent::__construct($message, 401);
    }
}

/**
 * Raised when the requested resource does not exist (HTTP 404).
 */
class NotFoundException extends RecommendAIException
{
    public function __construct(string $message = 'Resource not found')
    {
        parent::__construct($message, 404);
    }
}

/**
 * Raised on invalid request data (HTTP 400 / 422).
 */
class ValidationException extends RecommendAIException
{
    public function __construct(string $message = 'Validation error', int $statusCode = 422)
    {
        parent::__construct($message, $statusCode);
    }
}

/**
 * Raised when the client is rate-limited (HTTP 429).
 */
class RateLimitException extends RecommendAIException
{
    public function __construct(string $message = 'Rate limit exceeded')
    {
        parent::__construct($message, 429);
    }
}

/**
 * Raised on server-side errors (HTTP 5xx).
 */
class ServerException extends RecommendAIException
{
    public function __construct(string $message = 'Server error', int $statusCode = 500)
    {
        parent::__construct($message, $statusCode);
    }
}
