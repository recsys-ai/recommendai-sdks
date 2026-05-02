# Python SDK

## Installation

```bash
pip install recommendai
```

Requires Python 3.8+.

## Quick Start

```python
from recommendai import RecommendAIClient

client = RecommendAIClient(api_key="your_api_key")

# Check connectivity
print(client.ping())  # True

# Similar items
recs = client.recommendations.similar("item-123", limit=10)
for r in recs:
    print(r.item_id, r.score)

# Popular items
popular = client.recommendations.popular(limit=5, category="books")

# Bulk upsert catalogue items
client.items.upsert([
    {"item_id": "item-1", "properties": {"title": "Book A", "price": 12.99}},
    {"item_id": "item-2", "properties": {"title": "Book B", "price": 9.99}},
])
```

## Configuration

```python
from recommendai import RecommendAIClient, ClientConfig

client = RecommendAIClient(
    api_key="your_api_key",
    config=ClientConfig(
        base_url="https://api.recsys.ai",
        timeout=30,
    ),
)
```

## Error Handling

```python
from recommendai.exceptions import (
    AuthenticationError,
    NotFoundError,
    RateLimitError,
    ValidationError,
    ServerError,
)

try:
    recs = client.recommendations.similar("item-123")
except AuthenticationError:
    print("Invalid API key")
except NotFoundError:
    print("Item not found")
except RateLimitError:
    print("Slow down — rate limit hit")
```

## API Reference

### `RecommendAIClient`

| Method | Signature | Description |
|---|---|---|
| `ping` | `ping() -> bool` | Returns `True` if the API is healthy |

### `recommendations`

| Method | Signature | Returns |
|---|---|---|
| `similar` | `similar(item_id: str, limit: int = 10) -> List[Recommendation]` | Items similar to `item_id` |
| `popular` | `popular(limit: int = 10, category: str = None) -> List[Recommendation]` | Popular items |

### `items`

| Method | Signature | Returns |
|---|---|---|
| `upsert` | `upsert(items: List[dict]) -> List[Item]` | Created/updated items |
