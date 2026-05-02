"""RecSys.AI Python SDK - Official Python client for the RecSys.AI API."""

__version__ = "1.0.0"

from .client import AsyncRecommendAIClient, RecommendAIClient
from .exceptions import (
    RecommendAIError,
    AuthenticationError,
    NotFoundError,
    RateLimitError,
    ValidationError,
)
from .models import (
    Recommendation,
    User,
    Item,
    Interaction,
    InteractionType,
)

__all__ = [
    "RecommendAIClient",
    "AsyncRecommendAIClient",
    "RecommendAIError",
    "AuthenticationError",
    "NotFoundError",
    "RateLimitError",
    "ValidationError",
    "Recommendation",
    "User",
    "Item",
    "Interaction",
    "InteractionType",
]
