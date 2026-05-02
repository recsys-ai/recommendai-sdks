"""Client implementation for RecSys.AI SDK."""

from typing import Optional
import httpx

from .resources import (
    RecommendationsResource,
    UsersResource,
    ItemsResource,
    InteractionsResource,
)


class RecommendAIClient:
    """Synchronous client for RecSys.AI API."""

    def __init__(
        self,
        api_key: str,
        base_url: str = "http://localhost:8080",
        timeout: float = 30.0,
        max_retries: int = 3,
    ) -> None:
        """Initialize the RecommendAI client.

        Args:
            api_key: API key for authentication
            base_url: Base URL for the API
            timeout: Request timeout in seconds
            max_retries: Maximum number of retries for failed requests
        """
        self._api_key = api_key
        self._base_url = base_url.rstrip("/")
        
        self._client = httpx.Client(
            base_url=self._base_url,
            timeout=timeout,
            headers={
                "Authorization": f"Bearer {api_key}",
                "User-Agent": "recommendai-python/1.0.0",
            },
        )

        # Initialize resources
        self.recommendations = RecommendationsResource(self._client)
        self.users = UsersResource(self._client)
        self.items = ItemsResource(self._client)
        self.interactions = InteractionsResource(self._client)

    def ping(self) -> bool:
        """Return True if the API is reachable and healthy."""
        try:
            response = self._client.get("/health")
            return response.status_code == 200
        except Exception:
            return False

    def close(self) -> None:
        """Close the HTTP client."""
        self._client.close()

    def __enter__(self) -> "RecommendAIClient":
        return self

    def __exit__(self, *args: object) -> None:
        self.close()


class AsyncRecommendAIClient:
    """Asynchronous client for RecSys.AI API."""

    def __init__(
        self,
        api_key: str,
        base_url: str = "http://localhost:8080",
        timeout: float = 30.0,
        max_retries: int = 3,
    ) -> None:
        """Initialize the async RecommendAI client.

        Args:
            api_key: API key for authentication
            base_url: Base URL for the API
            timeout: Request timeout in seconds
            max_retries: Maximum number of retries for failed requests
        """
        self._api_key = api_key
        self._base_url = base_url.rstrip("/")
        
        self._client = httpx.AsyncClient(
            base_url=self._base_url,
            timeout=timeout,
            headers={
                "Authorization": f"Bearer {api_key}",
                "User-Agent": "recommendai-python/1.0.0",
            },
        )

        # Initialize resources
        from .resources import (
            AsyncRecommendationsResource,
            AsyncUsersResource,
            AsyncItemsResource,
            AsyncInteractionsResource,
        )
        
        self.recommendations = AsyncRecommendationsResource(self._client)
        self.users = AsyncUsersResource(self._client)
        self.items = AsyncItemsResource(self._client)
        self.interactions = AsyncInteractionsResource(self._client)

    async def ping(self) -> bool:
        """Return True if the API is reachable and healthy."""
        try:
            response = await self._client.get("/health")
            return response.status_code == 200
        except Exception:
            return False

    async def close(self) -> None:
        """Close the HTTP client."""
        await self._client.aclose()

    async def __aenter__(self) -> "AsyncRecommendAIClient":
        return self

    async def __aexit__(self, *args: object) -> None:
        await self.close()
