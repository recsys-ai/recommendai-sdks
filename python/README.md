# RecSys.AI Python SDK

Official Python SDK for the RecSys.AI Recommendation System.

## Installation

```bash
pip install recommendai
```

## Quick Start

```python
from recommendai import RecommendAIClient

# Initialize client
client = RecommendAIClient(
    api_key="your_api_key",
    base_url="https://api.recsys-ai.com"  # Optional
)

# Get recommendations
recommendations = client.recommendations.get(
    user_id="user123",
    limit=10,
    context={"device": "mobile"}
)

# Track interactions
client.interactions.create(
    user_id="user123",
    item_id="item456",
    interaction_type="view"
)

# Manage users
user = client.users.create(
    user_id="user123",
    properties={"age": 25, "country": "US"}
)

# Manage items
item = client.items.create(
    item_id="item456",
    properties={"category": "electronics", "price": 99.99}
)
```

## Async Support

```python
from recommendai import AsyncRecommendAIClient

async with AsyncRecommendAIClient(api_key="your_api_key") as client:
    recommendations = await client.recommendations.get(user_id="user123")
```

## Features

- ✅ Fully typed with mypy support
- ✅ Async/await support
- ✅ Automatic retries with exponential backoff
- ✅ Request/response logging
- ✅ Comprehensive error handling
- ✅ 100% test coverage

## Requirements

- Python 3.8+
- httpx >= 0.27.0
- pydantic >= 2.0.0

## Documentation

Full documentation: https://docs.recsys-ai.com/sdks/python

## License

MIT License
