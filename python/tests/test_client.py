"""Tests for RecommendAI client."""

import pytest
from unittest.mock import Mock, patch
import httpx

from recommendai import RecommendAIClient, AsyncRecommendAIClient
from recommendai.exceptions import AuthenticationError, NotFoundError


class TestRecommendAIClient:
    """Tests for synchronous client."""

    def test_client_initialization(self):
        """Test client initializes with correct parameters."""
        client = RecommendAIClient(api_key="test_key", base_url="https://api.test.com")
        
        assert client._api_key == "test_key"
        assert client._base_url == "https://api.test.com"
        assert client.recommendations is not None
        assert client.users is not None
        assert client.items is not None
        assert client.interactions is not None

    def test_client_context_manager(self):
        """Test client works as context manager."""
        with RecommendAIClient(api_key="test_key") as client:
            assert client is not None
        
        # Client should be closed after exiting context

    def test_client_close(self):
        """Test client closes properly."""
        client = RecommendAIClient(api_key="test_key")
        client.close()
        # Should not raise any errors


@pytest.mark.asyncio
class TestAsyncRecommendAIClient:
    """Tests for asynchronous client."""

    async def test_async_client_initialization(self):
        """Test async client initializes with correct parameters."""
        client = AsyncRecommendAIClient(api_key="test_key", base_url="https://api.test.com")
        
        assert client._api_key == "test_key"
        assert client._base_url == "https://api.test.com"
        assert client.recommendations is not None
        assert client.users is not None
        assert client.items is not None
        assert client.interactions is not None
        
        await client.close()

    async def test_async_client_context_manager(self):
        """Test async client works as context manager."""
        async with AsyncRecommendAIClient(api_key="test_key") as client:
            assert client is not None
        
        # Client should be closed after exiting context
