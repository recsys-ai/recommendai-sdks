"""Data models for RecSys.AI SDK."""

from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class InteractionType(str, Enum):
    """Types of user-item interactions."""

    VIEW = "view"
    CLICK = "click"
    PURCHASE = "purchase"
    LIKE = "like"
    DISLIKE = "dislike"
    RATING = "rating"
    CART_ADD = "cart_add"
    CART_REMOVE = "cart_remove"


class Recommendation(BaseModel):
    """A recommendation for a user."""

    item_id: str = Field(..., description="Unique identifier for the item")
    score: float = Field(..., description="Recommendation score (0-1)")
    reason: Optional[str] = Field(None, description="Explanation for the recommendation")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")


class User(BaseModel):
    """A user in the recommendation system."""

    user_id: str = Field(..., description="Unique identifier for the user")
    properties: Dict[str, Any] = Field(default_factory=dict, description="User properties")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class Item(BaseModel):
    """An item in the recommendation system."""

    item_id: str = Field(..., description="Unique identifier for the item")
    properties: Dict[str, Any] = Field(default_factory=dict, description="Item properties")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class Interaction(BaseModel):
    """A user-item interaction."""

    interaction_id: Optional[str] = Field(None, description="Unique interaction ID")
    user_id: str = Field(..., description="User who performed the interaction")
    item_id: str = Field(..., description="Item that was interacted with")
    interaction_type: InteractionType = Field(..., description="Type of interaction")
    value: Optional[float] = Field(None, description="Interaction value (e.g., rating)")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")


class RecommendationRequest(BaseModel):
    """Request for recommendations."""

    user_id: str
    limit: int = Field(default=10, ge=1, le=100)
    context: Dict[str, Any] = Field(default_factory=dict)
    filters: Dict[str, Any] = Field(default_factory=dict)


class RecommendationResponse(BaseModel):
    """Response containing recommendations."""

    user_id: str
    recommendations: List[Recommendation]
    request_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
