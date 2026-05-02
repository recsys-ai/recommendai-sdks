namespace RecommendAI;

/// <summary>Base exception for all RecSys.AI API errors.</summary>
public class RecommendAIException : Exception
{
    public int StatusCode { get; }
    public RecommendAIException(string message, int statusCode = 0) : base(message)
        => StatusCode = statusCode;
}

/// <summary>Thrown when the API key is invalid or missing (HTTP 401).</summary>
public sealed class AuthenticationException : RecommendAIException
{
    public AuthenticationException(string message) : base(message, 401) { }
}

/// <summary>Thrown when a requested resource does not exist (HTTP 404).</summary>
public sealed class NotFoundException : RecommendAIException
{
    public NotFoundException(string message) : base(message, 404) { }
}

/// <summary>Thrown when request validation fails (HTTP 400 / 422).</summary>
public sealed class ValidationException : RecommendAIException
{
    public ValidationException(string message, int statusCode = 422) : base(message, statusCode) { }
}

/// <summary>Thrown when the rate limit is exceeded (HTTP 429).</summary>
public sealed class RateLimitException : RecommendAIException
{
    public RateLimitException(string message) : base(message, 429) { }
}

/// <summary>Thrown for unexpected server-side errors (HTTP 5xx).</summary>
public sealed class ServerException : RecommendAIException
{
    public ServerException(string message, int statusCode) : base(message, statusCode) { }
}
