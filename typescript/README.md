# RecSys.AI TypeScript SDK

Official TypeScript/JavaScript SDK for the RecSys.AI Recommendation System.

## Installation

```bash
npm install @recommendai/sdk
# or
yarn add @recommendai/sdk
```

## Quick Start

```typescript
import { RecommendAIClient } from '@recommendai/sdk';

const client = new RecommendAIClient({
  apiKey: 'your_api_key',
  baseUrl: 'https://api.recsys-ai.com' // Optional
});

// Get recommendations
const recommendations = await client.recommendations.get({
  userId: 'user123',
  limit: 10
});

// Track interactions
await client.interactions.create({
  userId: 'user123',
  itemId: 'item456',
  interactionType: 'view'
});
```

## Features

- ✅ Full TypeScript support
- ✅ Promise-based async/await API
- ✅ Automatic request retries
- ✅ Built-in error handling
- ✅ 100% test coverage

## Documentation

Full documentation: https://docs.recsys-ai.com/sdks/typescript

## License

MIT
