# TypeScript SDK

## Installation

```bash
npm install @recommendai/sdk
# or
yarn add @recommendai/sdk
```

Requires Node.js 18+ or any modern browser/Deno environment.

## Quick Start

```typescript
import { RecommendAIClient } from "@recommendai/sdk";

const client = new RecommendAIClient({ apiKey: "your_api_key" });

// Health check
const alive = await client.ping(); // true

// Similar items
const similar = await client.recommendations.similar("item-123", { limit: 10 });
similar.forEach(r => console.log(r.itemId, r.score));

// Popular items
const popular = await client.recommendations.popular({ limit: 5, category: "books" });

// Bulk upsert
await client.items.upsert([
    { itemId: "item-1", properties: { title: "Book A" } },
    { itemId: "item-2", properties: { title: "Book B" } },
]);
```

## Configuration

```typescript
const client = new RecommendAIClient({
    apiKey: "your_api_key",
    baseUrl: "https://api.recsys.ai",
    timeout: 30_000,
});
```

## Error Handling

```typescript
import {
    AuthenticationError,
    NotFoundError,
    RateLimitError,
} from "@recommendai/sdk";

try {
    const recs = await client.recommendations.similar("item-123");
} catch (err) {
    if (err instanceof AuthenticationError) {
        console.error("Invalid API key");
    } else if (err instanceof RateLimitError) {
        console.error("Rate limit exceeded");
    } else {
        throw err;
    }
}
```

## API Reference

### `RecommendAIClient`

| Method | Signature | Description |
|---|---|---|
| `ping` | `ping(): Promise<boolean>` | `true` if the API is reachable |

### `recommendations`

| Method | Signature | Returns |
|---|---|---|
| `similar` | `similar(itemId: string, opts?: { limit?: number }): Promise<Recommendation[]>` | Similar items |
| `popular` | `popular(opts?: { limit?: number; category?: string }): Promise<Recommendation[]>` | Popular items |

### `items`

| Method | Signature | Returns |
|---|---|---|
| `upsert` | `upsert(items: ItemInput[]): Promise<Item[]>` | Upserted items |
