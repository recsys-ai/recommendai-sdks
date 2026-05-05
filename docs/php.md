# PHP SDK

## Installation

```bash
composer require recsys-ai/recommendai
```

Requires PHP 8.1+ and the `ext-json` extension.

## Quick Start

```php
<?php
use RecommendAI\RecommendAIClient;

$client = new RecommendAIClient('your_api_key');

// Health check
var_dump($client->ping()); // bool(true)

// Similar items
$similar = $client->recommendations()->similar('item-123', limit: 10);
foreach ($similar as $rec) {
    echo $rec->itemId . ' ' . $rec->score . PHP_EOL;
}

// Popular items
$popular = $client->recommendations()->popular(limit: 5, category: 'books');

// Bulk upsert
$client->items()->upsert([
    ['item_id' => 'item-1', 'properties' => ['title' => 'Book A']],
]);
```

## Configuration

```php
use RecommendAI\ClientConfig;

$client = new RecommendAIClient(
    'your_api_key',
    baseUrl: 'https://api.recsys.ai',
    timeout: 30,
);
```

## Error Handling

```php
use RecommendAI\Exceptions\AuthenticationException;
use RecommendAI\Exceptions\NotFoundException;
use RecommendAI\Exceptions\RateLimitException;

try {
    $recs = $client->recommendations()->similar('item-123');
} catch (AuthenticationException $e) {
    error_log('Invalid API key: ' . $e->getMessage());
} catch (NotFoundException $e) {
    error_log('Not found: ' . $e->getMessage());
} catch (RateLimitException $e) {
    error_log('Rate limited: ' . $e->getMessage());
}
```

## API Reference

### `RecommendAIClient`

| Method | Returns | Description |
|---|---|---|
| `ping()` | `bool` | `true` if API is healthy |

### `recommendations()` method

| Method | Returns |
|---|---|
| `similar(itemId, limit)` | `array<Recommendation>` |
| `popular(limit, category?)` | `array<Recommendation>` |

### `items()` method

| Method | Returns |
|---|---|
| `upsert(items)` | `array<Item>` |
