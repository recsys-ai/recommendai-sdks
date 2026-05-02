# RecSys.AI PHP SDK

Official PHP client for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- PHP 8.1+
- [Composer](https://getcomposer.org/)

## Installation

```bash
composer require recsys-ai/recommendai
```

## Quick Start

```php
<?php

require 'vendor/autoload.php';

use RecommendAI\RecommendAIClient;
use RecommendAI\InteractionType;

$client = new RecommendAIClient(apiKey: 'your_api_key');

// Create a user
$user = $client->users()->create('user-123', ['name' => 'Alice', 'age' => 28]);

// Add an item to the catalogue
$item = $client->items()->create('item-456', ['title' => 'Inception', 'genre' => 'sci-fi']);

// Record an interaction
$client->interactions()->create(
    userId: 'user-123',
    itemId: 'item-456',
    interactionType: InteractionType::VIEW,
);

// Get personalised recommendations
$recs = $client->recommendations()->get('user-123', 10);
foreach ($recs as $r) {
    printf("%s  score=%.4f  %s\n", $r->item_id, $r->score, $r->reason);
}
```

## Configuration

```php
$client = new RecommendAIClient(
    apiKey:  'your_api_key',
    baseUrl: 'https://api.recsys-ai.com',   // default
    timeout: 30,                             // seconds, default
);
```

## API Reference

### Recommendations

```php
$recs = $client->recommendations()->get('user-123', limit: 10);
// Recommendation->item_id, ->score, ->reason, ->metadata
```

### Users

```php
$user = $client->users()->create('user-123', ['name' => 'Alice']);
$user = $client->users()->get('user-123');
$user = $client->users()->update('user-123', ['subscription' => 'premium']);
$client->users()->delete('user-123');
```

### Items

```php
$item = $client->items()->create('item-456', ['title' => 'Inception']);
$item = $client->items()->get('item-456');
$item = $client->items()->update('item-456', ['remastered' => true]);
$client->items()->delete('item-456');
```

### Interactions

```php
use RecommendAI\InteractionType;

// Simple
$client->interactions()->create('user-123', 'item-456', InteractionType::VIEW);

// With rating
$client->interactions()->create(
    userId:          'user-123',
    itemId:          'item-456',
    interactionType: InteractionType::RATING,
    value:           8.5,
);
```

Available types: `VIEW`, `CLICK`, `PURCHASE`, `LIKE`, `DISLIKE`, `RATING`, `CART_ADD`, `CART_REMOVE`.

## Error Handling

```php
use RecommendAI\NotFoundException;
use RecommendAI\AuthenticationException;
use RecommendAI\RateLimitException;
use RecommendAI\RecommendAIException;

try {
    $client->users()->get('ghost');
} catch (NotFoundException $e) {
    echo "Not found: {$e->getMessage()}\n";
} catch (AuthenticationException $e) {
    echo "Auth error: {$e->getMessage()}\n";
} catch (RateLimitException $e) {
    echo "Rate limited: {$e->getMessage()}\n";
} catch (RecommendAIException $e) {
    echo "API error ({$e->statusCode}): {$e->getMessage()}\n";
}
```

## Running the Simulation Example

The simulation uses the PHP built-in HTTP server as an in-process mock (port 17896).
No live API key or service required.

```bash
# Install dependencies first
composer install

# Run the simulation
php examples/simulation.php
```

## License

MIT
