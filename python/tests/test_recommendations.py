"""Tests for recommendations resource."""

import pytest
from unittest.mock import Mock, MagicMock
import httpx

from recommendai.resources import RecommendationsResource, AsyncRecommendationsResource
from recommendai.models import Recommendation


class TestRecommendationsResource:
    """Tests for synchronous recommendations resource."""

    def test_get_recommendations_success(self):
        """Test successful recommendation retrieval."""
        # Mock HTTP client
        mock_client = Mock(spec=httpx.Client)
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "recommendations": [
                {"item_id": "item1", "score": 0.95, "reason": "Popular", "metadata": {}},
                {"item_id": "item2", "score": 0.85, "reason": "Similar", "metadata": {}},
            ]
        }
        mock_response.content = b'{"recommendations": []}'
        mock_response.raise_for_status = Mock()
        mock_client.get.return_value = mock_response

        # Test
        resource = RecommendationsResource(mock_client)
        recommendations = resource.get(user_id="user123", limit=10)

        # Assertions
        assert len(recommendations) == 2
        assert all(isinstance(r, Recommendation) for r in recommendations)
        assert recommendations[0].item_id == "item1"
        assert recommendations[0].score == 0.95
        assert recommendations[1].item_id == "item2"

        # Verify API call
        mock_client.get.assert_called_once()
        call_args = mock_client.get.call_args
        assert call_args[0][0] == "/api/recommendations"
        assert call_args[1]["params"]["user_id"] == "user123"
        assert call_args[1]["params"]["limit"] == 10

    def test_get_recommendations_with_context(self):
        """Test recommendations with context."""
        mock_client = Mock(spec=httpx.Client)
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"recommendations": []}
        mock_response.content = b'{"recommendations": []}'
        mock_response.raise_for_status = Mock()
        mock_client.get.return_value = mock_response

        resource = RecommendationsResource(mock_client)
        context = {"device": "mobile", "location": "US"}
        resource.get(user_id="user123", context=context)

        call_args = mock_client.get.call_args
        assert "context" in call_args[1]["params"]


@pytest.mark.asyncio
class TestAsyncRecommendationsResource:
    """Tests for async recommendations resource."""

    async def test_get_recommendations_success(self):
        """Test successful async recommendation retrieval."""
        # Mock async HTTP client
        mock_client = Mock(spec=httpx.AsyncClient)
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "recommendations": [
                {"item_id": "item1", "score": 0.95, "reason": "Popular", "metadata": {}},
            ]
        }
        mock_response.content = b'{"recommendations": []}'
        mock_response.raise_for_status = Mock()
        
        # Make the get method return a coroutine
        async def mock_get(*args, **kwargs):
            return mock_response
        
        mock_client.get = mock_get

        # Test
        resource = AsyncRecommendationsResource(mock_client)
        recommendations = await resource.get(user_id="user123", limit=10)

        # Assertions
        assert len(recommendations) == 1
        assert recommendations[0].item_id == "item1"
