# Dart SDK

## Installation

```bash
dart pub add recommendai
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  recommendai: ^1.0.0
```

Requires Dart 3.0+ (Flutter 3.10+).

## Quick Start

```dart
import 'package:recommendai/recommendai.dart';

void main() async {
  final client = RecommendAIClient(apiKey: 'your_api_key');

  // Health check
  final alive = await client.ping();
  print(alive); // true

  // Similar items
  final similar = await client.recommendations.similar('item-123', limit: 10);
  for (final r in similar) {
    print('${r.itemId} — ${r.score}');
  }

  // Popular items
  final popular = await client.recommendations.popular(limit: 5, category: 'books');

  // Bulk upsert
  final items = await client.items.upsert([
    {'item_id': 'item-1', 'properties': {'title': 'Book A'}},
  ]);

  client.close();
}
```

## Configuration

```dart
final client = RecommendAIClient(
  apiKey: 'your_api_key',
  config: ClientConfig(
    baseUrl: 'https://api.recsys.ai',
    timeout: Duration(seconds: 30),
  ),
);
```

## Error Handling

```dart
import 'package:recommendai/recommendai.dart';

try {
  final recs = await client.recommendations.similar('item-123');
} on AuthenticationError catch (e) {
  print('Authentication failed: $e');
} on NotFoundError catch (e) {
  print('Not found: $e');
} on RateLimitError catch (e) {
  print('Rate limited: $e');
}
```

## API Reference

### `RecommendAIClient`

| Method | Returns | Description |
|---|---|---|
| `ping()` | `Future<bool>` | `true` if API is healthy |

### `recommendations`

| Method | Returns |
|---|---|
| `similar(itemId, {limit})` | `Future<List<Recommendation>>` |
| `popular({limit, category})` | `Future<List<Recommendation>>` |

### `items`

| Method | Returns |
|---|---|
| `upsert(items)` | `Future<List<Item>>` |
