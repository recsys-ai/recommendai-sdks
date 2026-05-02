# RecSys.AI Dart SDK

Official Dart/Flutter client for the [RecSys.AI](https://recsys-ai.com) personalised-recommendation platform.

## Requirements

- Dart SDK ≥ 3.0.0

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  recommendai: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:recommendai/recommendai.dart';

Future<void> main() async {
  final client = RecommendAIClient(apiKey: 'your_api_key');

  // Create a user
  final user = await client.users.create('user-123',
      properties: {'name': 'Alice', 'age': 28});

  // Record an interaction
  await client.interactions.create(
    'user-123', 'item-456', InteractionType.view);

  // Get recommendations
  final recs = await client.recommendations.get('user-123', limit: 10);
  for (final r in recs) {
    print('${r.itemId}: ${r.score.toStringAsFixed(4)}  ${r.reason}');
  }

  client.close();
}
```

## Configuration

```dart
final client = RecommendAIClient(
  apiKey:  'your_api_key',
  baseUrl: 'https://api.recsys-ai.com',
  timeout: const Duration(seconds: 30),
);
```

## API Reference

### Recommendations

```dart
final recs = await client.recommendations.get('user-123', limit: 10);
```

### Users

```dart
await client.users.create('user-123', properties: {'name': 'Alice'});
await client.users.getUser('user-123');
await client.users.update('user-123', {'subscription': 'premium'});
await client.users.delete('user-123');
```

### Items

```dart
await client.items.create('item-456', properties: {'title': 'Inception'});
await client.items.getItem('item-456');
await client.items.update('item-456', {'remastered': true});
await client.items.delete('item-456');
```

### Interactions

```dart
await client.interactions.create('user-123', 'item-456', InteractionType.view);
await client.interactions.create('user-123', 'item-456', InteractionType.rating, value: 8.5);
```

Available types: `view`, `like`, `dislike`, `purchase`, `rating`, `share`, `bookmark`

## Error Handling

```dart
try {
  await client.users.getUser('ghost');
} on NotFoundException catch (e) {
  print('Not found: ${e.message}');
} on AuthenticationException catch (e) {
  print('Auth error: ${e.message}');
} on RecommendAIException catch (e) {
  print('API error [${e.statusCode}]: ${e.message}');
}
```

## Running the Simulation

The simulation starts a `dart:io HttpServer` mock on port 17899.
No live API key or service is required.

```bash
dart run example/simulation.dart
```

## License

MIT
