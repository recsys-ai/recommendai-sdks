"""Custom exceptions for RecSys.AI SDK."""
from typing import Optional


class RecommendAIError(Exception):
    """Base exception for all RecommendAI errors."""

    def __init__(self, message: str, status_code: Optional[int] = None) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class AuthenticationError(RecommendAIError):
    """Raised when authentication fails (401)."""

    def __init__(self, message: str = "Authentication failed") -> None:
        super().__init__(message, status_code=401)


class NotFoundError(RecommendAIError):
    """Raised when a resource is not found (404)."""

    def __init__(self, message: str = "Resource not found") -> None:
        super().__init__(message, status_code=404)


class ValidationError(RecommendAIError):
    """Raised when request validation fails (400/422)."""

    def __init__(self, message: str = "Validation error") -> None:
        super().__init__(message, status_code=400)


class RateLimitError(RecommendAIError):
    """Raised when rate limit is exceeded (429)."""

    def __init__(self, message: str = "Rate limit exceeded") -> None:
        super().__init__(message, status_code=429)


class ServerError(RecommendAIError):
    """Raised when server returns 5xx error."""

    def __init__(self, message: str = "Server error") -> None:
        super().__init__(message, status_code=500)
