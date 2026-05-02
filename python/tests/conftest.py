"""Pytest configuration."""

import pytest


@pytest.fixture
def mock_api_key():
    """Provide a mock API key for testing."""
    return "test_api_key_12345"


@pytest.fixture
def mock_base_url():
    """Provide a mock base URL for testing."""
    return "https://api.test.recsys-ai.com"
