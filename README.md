# RecSys.AI SDK

Official client libraries for the [RecSys.AI](https://recsys.ai) recommendation platform, available in **11 languages**.

[![CI](https://github.com/recsys-ai/recommendai-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/recsys-ai/recommendai-sdk/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-recsys--ai.github.io-blue)](https://recsys-ai.github.io/recommendai-sdk/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Installation

| Language | Install |
|---|---|
| **Python** | `pip install recommendai` |
| **TypeScript** | `npm install @recommendai/sdk` |
| **Go** | `go get github.com/recsys-ai/recommendai-sdk/go/recommendai` |
| **Dart** | `dart pub add recommendai` |
| **.NET** | `dotnet add package RecommendAI` |
| **Java** | Maven / Gradle — see [docs](https://recsys-ai.github.io/recommendai-sdk/java/) |
| **Kotlin** | Gradle — see [docs](https://recsys-ai.github.io/recommendai-sdk/kotlin/) |
| **PHP** | `composer require recommendai/sdk` |
| **Ruby** | `gem install recommendai` |
| **Rust** | `recommendai = "1"` in `Cargo.toml` |
| **Swift** | SwiftPM — see [docs](https://recsys-ai.github.io/recommendai-sdk/swift/) |

---

## Quick Start

```python
# Python
from recommendai import RecommendAIClient

client = RecommendAIClient(api_key="your_api_key")

# Items similar to a given item
recs = client.recommendations.similar("item-123", limit=10)

# Globally popular items
popular = client.recommendations.popular(limit=10, category="electronics")

# Bulk upsert catalogue items
client.items.upsert([
    {"item_id": "item-1", "properties": {"title": "Book A"}},
])

# Health check
alive = client.ping()  # True
```

---

## Core Methods

All SDKs expose the same four operations:

| Method | Description |
|---|---|
| `similar(itemId, limit)` | Items similar to the given item |
| `popular(limit, category?)` | Globally popular items, optionally filtered by category |
| `upsert(items)` | Bulk create or update items in the catalogue |
| `ping()` | Health check — returns `true` if the API is reachable |

---

## Documentation

Full documentation, including per-language API references and error handling guides, is available at:

**[https://recsys-ai.github.io/recommendai-sdk/](https://recsys-ai.github.io/recommendai-sdk/)**

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE) © 2024 RecSys.AI
