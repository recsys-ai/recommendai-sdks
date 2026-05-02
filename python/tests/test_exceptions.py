"""Tests for exceptions."""

import pytest

from recommendai.exceptions import (
    RecommendAIError,
    AuthenticationError,
    NotFoundError,
    ValidationError,
    RateLimitError,
    ServerError,
)


class TestExceptions:
    """Tests for custom exceptions."""

    def test_base_exception(self):
        """Test base RecommendAIError."""
        error = RecommendAIError("Test error", status_code=400)
        
        assert str(error) == "Test error"
        assert error.message == "Test error"
        assert error.status_code == 400

    def test_authentication_error(self):
        """Test AuthenticationError."""
        error = AuthenticationError()
        
        assert error.status_code == 401
        assert "Authentication failed" in str(error)

    def test_not_found_error(self):
        """Test NotFoundError."""
        error = NotFoundError("User not found")
        
        assert error.status_code == 404
        assert "User not found" in str(error)

    def test_validation_error(self):
        """Test ValidationError."""
        error = ValidationError("Invalid input")
        
        assert error.status_code == 400
        assert "Invalid input" in str(error)

    def test_rate_limit_error(self):
        """Test RateLimitError."""
        error = RateLimitError()
        
        assert error.status_code == 429
        assert "Rate limit exceeded" in str(error)

    def test_server_error(self):
        """Test ServerError."""
        error = ServerError("Internal server error")
        
        assert error.status_code == 500
        assert "Internal server error" in str(error)

    def test_exception_inheritance(self):
        """Test that all exceptions inherit from base."""
        errors = [
            AuthenticationError(),
            NotFoundError(),
            ValidationError(),
            RateLimitError(),
            ServerError(),
        ]
        
        for error in errors:
            assert isinstance(error, RecommendAIError)
            assert isinstance(error, Exception)
