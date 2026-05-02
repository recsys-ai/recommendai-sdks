"""Resource classes for API endpoints."""

from typing import Any, Dict, List, Optional, Union

import httpx

from .exceptions import (
    AuthenticationError,
    NotFoundError,
    RateLimitError,
    ServerError,
    ValidationError,
)
from .models import Interaction, InteractionType, Item, Recommendation, User


def _handle_response(response: httpx.Response) -> Any:
    """Handle HTTP response and raise appropriate exceptions."""
    if response.status_code == 401:
        raise AuthenticationError(response.json().get("detail", "Authentication failed"))
    elif response.status_code == 404:
        raise NotFoundError(response.json().get("detail", "Resource not found"))
    elif response.status_code == 429:
        raise RateLimitError(response.json().get("detail", "Rate limit exceeded"))
    elif 400 <= response.status_code < 500:
        raise ValidationError(response.json().get("detail", "Validation error"))
    elif response.status_code >= 500:
        raise ServerError(response.json().get("detail", "Server error"))
    
    response.raise_for_status()
    return response.json() if response.content else None


class RecommendationsResource:
    """Recommendations API resource."""

    def __init__(self, client: httpx.Client) -> None:
        self._client = client

    def get(
        self,
        user_id: str,
        limit: int = 10,
        context: Optional[Dict[str, Any]] = None,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[Recommendation]:
        """Get recommendations for a user."""
        params = {"user_id": user_id, "limit": limit}
        if context:
            params["context"] = context
        if filters:
            params["filters"] = filters

        response = self._client.get("/api/recommendations", params=params)
        data = _handle_response(response)
        return [Recommendation(**item) for item in data.get("recommendations", [])]

    def similar(self, item_id: str, limit: int = 10) -> List[Recommendation]:
        """Get items similar to a given item."""
        params = {"limit": limit}
        response = self._client.get(f"/api/recommendations/similar/{item_id}", params=params)
        data = _handle_response(response)
        return [Recommendation(**item) for item in data.get("recommendations", [])]

    def popular(self, limit: int = 10, category: Optional[str] = None) -> List[Recommendation]:
        """Get globally popular items."""
        params: Dict[str, Any] = {"limit": limit}
        if category:
            params["category"] = category
        response = self._client.get("/api/recommendations/popular", params=params)
        data = _handle_response(response)
        return [Recommendation(**item) for item in data.get("recommendations", [])]


class AsyncRecommendationsResource:
    """Async Recommendations API resource."""

    def __init__(self, client: httpx.AsyncClient) -> None:
        self._client = client

    async def get(
        self,
        user_id: str,
        limit: int = 10,
        context: Optional[Dict[str, Any]] = None,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[Recommendation]:
        """Get recommendations for a user."""
        params = {"user_id": user_id, "limit": limit}
        if context:
            params["context"] = context
        if filters:
            params["filters"] = filters

        response = await self._client.get("/api/recommendations", params=params)
        data = _handle_response(response)
        return [Recommendation(**item) for item in data.get("recommendations", [])]

    async def similar(self, item_id: str, limit: int = 10) -> List[Recommendation]:
        """Get items similar to a given item."""
        params = {"limit": limit}
        response = await self._client.get(f"/api/recommendations/similar/{item_id}", params=params)
        data = _handle_response(response)
        return [Recommendation(**item) for item in data.get("recommendations", [])]

    async def popular(self, limit: int = 10, category: Optional[str] = None) -> List[Recommendation]:
        """Get globally popular items."""
        params: Dict[str, Any] = {"limit": limit}
        if category:
            params["category"] = category
        response = await self._client.get("/api/recommendations/popular", params=params)
        data = _handle_response(response)
        return [Recommendation(**item) for item in data.get("recommendations", [])]


class UsersResource:
    """Users API resource."""

    def __init__(self, client: httpx.Client) -> None:
        self._client = client

    def create(self, user_id: str, properties: Optional[Dict[str, Any]] = None) -> User:
        """Create a new user."""
        data = {"user_id": user_id, "properties": properties or {}}
        response = self._client.post("/api/users", json=data)
        return User(**_handle_response(response))

    def get(self, user_id: str) -> User:
        """Get a user by ID."""
        response = self._client.get(f"/api/users/{user_id}")
        return User(**_handle_response(response))

    def update(self, user_id: str, properties: Dict[str, Any]) -> User:
        """Update a user."""
        response = self._client.put(f"/api/users/{user_id}", json={"properties": properties})
        return User(**_handle_response(response))

    def delete(self, user_id: str) -> None:
        """Delete a user."""
        response = self._client.delete(f"/api/users/{user_id}")
        _handle_response(response)


class AsyncUsersResource:
    """Async Users API resource."""

    def __init__(self, client: httpx.AsyncClient) -> None:
        self._client = client

    async def create(self, user_id: str, properties: Optional[Dict[str, Any]] = None) -> User:
        """Create a new user."""
        data = {"user_id": user_id, "properties": properties or {}}
        response = await self._client.post("/api/users", json=data)
        return User(**_handle_response(response))

    async def get(self, user_id: str) -> User:
        """Get a user by ID."""
        response = await self._client.get(f"/api/users/{user_id}")
        return User(**_handle_response(response))

    async def update(self, user_id: str, properties: Dict[str, Any]) -> User:
        """Update a user."""
        response = await self._client.put(f"/api/users/{user_id}", json={"properties": properties})
        return User(**_handle_response(response))

    async def delete(self, user_id: str) -> None:
        """Delete a user."""
        response = await self._client.delete(f"/api/users/{user_id}")
        _handle_response(response)


class ItemsResource:
    """Items API resource."""

    def __init__(self, client: httpx.Client) -> None:
        self._client = client

    def create(self, item_id: str, properties: Optional[Dict[str, Any]] = None) -> Item:
        """Create a new item."""
        data = {"item_id": item_id, "properties": properties or {}}
        response = self._client.post("/api/items", json=data)
        return Item(**_handle_response(response))

    def get(self, item_id: str) -> Item:
        """Get an item by ID."""
        response = self._client.get(f"/api/items/{item_id}")
        return Item(**_handle_response(response))

    def update(self, item_id: str, properties: Dict[str, Any]) -> Item:
        """Update an item."""
        response = self._client.put(f"/api/items/{item_id}", json={"properties": properties})
        return Item(**_handle_response(response))

    def delete(self, item_id: str) -> None:
        """Delete an item."""
        response = self._client.delete(f"/api/items/{item_id}")
        _handle_response(response)

    def upsert(self, items: List[Dict[str, Any]]) -> List[Item]:
        """Bulk upsert (create or update) a list of items."""
        response = self._client.post("/api/items/bulk", json={"items": items})
        data = _handle_response(response)
        return [Item(**i) for i in data.get("items", [])]


class AsyncItemsResource:
    """Async Items API resource."""

    def __init__(self, client: httpx.AsyncClient) -> None:
        self._client = client

    async def create(self, item_id: str, properties: Optional[Dict[str, Any]] = None) -> Item:
        """Create a new item."""
        data = {"item_id": item_id, "properties": properties or {}}
        response = await self._client.post("/api/items", json=data)
        return Item(**_handle_response(response))

    async def get(self, item_id: str) -> Item:
        """Get an item by ID."""
        response = await self._client.get(f"/api/items/{item_id}")
        return Item(**_handle_response(response))

    async def update(self, item_id: str, properties: Dict[str, Any]) -> Item:
        """Update an item."""
        response = await self._client.put(f"/api/items/{item_id}", json={"properties": properties})
        return Item(**_handle_response(response))

    async def upsert(self, items: List[Dict[str, Any]]) -> List[Item]:
        """Bulk upsert (create or update) a list of items."""
        response = await self._client.post("/api/items/bulk", json={"items": items})
        data = _handle_response(response)
        return [Item(**i) for i in data.get("items", [])]

    async def delete(self, item_id: str) -> None:
        """Delete an item."""
        response = await self._client.delete(f"/api/items/{item_id}")
        _handle_response(response)


class InteractionsResource:
    """Interactions API resource."""

    def __init__(self, client: httpx.Client) -> None:
        self._client = client

    def create(
        self,
        user_id: str,
        item_id: str,
        interaction_type: Union[InteractionType, str],
        value: Optional[float] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Interaction:
        """Create a new interaction."""
        data = {
            "user_id": user_id,
            "item_id": item_id,
            "interaction_type": interaction_type,
            "value": value,
            "metadata": metadata or {},
        }
        response = self._client.post("/api/interactions", json=data)
        return Interaction(**_handle_response(response))


class AsyncInteractionsResource:
    """Async Interactions API resource."""

    def __init__(self, client: httpx.AsyncClient) -> None:
        self._client = client

    async def create(
        self,
        user_id: str,
        item_id: str,
        interaction_type: Union[InteractionType, str],
        value: Optional[float] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Interaction:
        """Create a new interaction."""
        data = {
            "user_id": user_id,
            "item_id": item_id,
            "interaction_type": interaction_type,
            "value": value,
            "metadata": metadata or {},
        }
        response = await self._client.post("/api/interactions", json=data)
        return Interaction(**_handle_response(response))
