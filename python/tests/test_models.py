"""Tests for data models."""

import pytest
from datetime import datetime

from recommendai.models import (
    Recommendation,
    User,
    Item,
    Interaction,
    InteractionType,
    RecommendationRequest,
)


class TestRecommendation:
    """Tests for Recommendation model."""

    def test_recommendation_creation(self):
        """Test creating a recommendation."""
        rec = Recommendation(
            item_id="item123",
            score=0.95,
            reason="Popular item",
            metadata={"category": "electronics"}
        )
        
        assert rec.item_id == "item123"
        assert rec.score == 0.95
        assert rec.reason == "Popular item"
        assert rec.metadata["category"] == "electronics"

    def test_recommendation_without_optional_fields(self):
        """Test recommendation with only required fields."""
        rec = Recommendation(item_id="item123", score=0.85)
        
        assert rec.item_id == "item123"
        assert rec.score == 0.85
        assert rec.reason is None
        assert rec.metadata == {}


class TestUser:
    """Tests for User model."""

    def test_user_creation(self):
        """Test creating a user."""
        user = User(
            user_id="user123",
            properties={"age": 25, "country": "US"}
        )
        
        assert user.user_id == "user123"
        assert user.properties["age"] == 25
        assert user.properties["country"] == "US"
        assert isinstance(user.created_at, datetime)
        assert isinstance(user.updated_at, datetime)

    def test_user_with_empty_properties(self):
        """Test user with no properties."""
        user = User(user_id="user123")
        
        assert user.user_id == "user123"
        assert user.properties == {}


class TestItem:
    """Tests for Item model."""

    def test_item_creation(self):
        """Test creating an item."""
        item = Item(
            item_id="item456",
            properties={"name": "Product A", "price": 99.99}
        )
        
        assert item.item_id == "item456"
        assert item.properties["name"] == "Product A"
        assert item.properties["price"] == 99.99
        assert isinstance(item.created_at, datetime)


class TestInteraction:
    """Tests for Interaction model."""

    def test_interaction_creation(self):
        """Test creating an interaction."""
        interaction = Interaction(
            user_id="user123",
            item_id="item456",
            interaction_type=InteractionType.VIEW,
            value=1.0,
            metadata={"source": "homepage"}
        )
        
        assert interaction.user_id == "user123"
        assert interaction.item_id == "item456"
        assert interaction.interaction_type == InteractionType.VIEW
        assert interaction.value == 1.0
        assert interaction.metadata["source"] == "homepage"
        assert isinstance(interaction.timestamp, datetime)

    def test_interaction_types(self):
        """Test all interaction types."""
        types = [
            InteractionType.VIEW,
            InteractionType.CLICK,
            InteractionType.PURCHASE,
            InteractionType.LIKE,
            InteractionType.DISLIKE,
            InteractionType.RATING,
            InteractionType.CART_ADD,
            InteractionType.CART_REMOVE,
        ]
        
        for interaction_type in types:
            interaction = Interaction(
                user_id="user123",
                item_id="item456",
                interaction_type=interaction_type
            )
            assert interaction.interaction_type == interaction_type


class TestRecommendationRequest:
    """Tests for RecommendationRequest model."""

    def test_request_creation(self):
        """Test creating a recommendation request."""
        request = RecommendationRequest(
            user_id="user123",
            limit=20,
            context={"device": "mobile"},
            filters={"category": "electronics"}
        )
        
        assert request.user_id == "user123"
        assert request.limit == 20
        assert request.context["device"] == "mobile"
        assert request.filters["category"] == "electronics"

    def test_request_with_defaults(self):
        """Test request with default values."""
        request = RecommendationRequest(user_id="user123")
        
        assert request.user_id == "user123"
        assert request.limit == 10
        assert request.context == {}
        assert request.filters == {}

    def test_request_limit_validation(self):
        """Test limit validation."""
        # Valid limits
        request1 = RecommendationRequest(user_id="user123", limit=1)
        assert request1.limit == 1
        
        request2 = RecommendationRequest(user_id="user123", limit=100)
        assert request2.limit == 100
