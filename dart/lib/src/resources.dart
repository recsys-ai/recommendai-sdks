import 'dart:convert';
import 'client.dart';
import 'models.dart';

// ── RecommendationsResource ───────────────────────────────────────────────────

class RecommendationsResource {
  final RecommendAIClient _client;
  const RecommendationsResource(this._client);

  Future<List<Recommendation>> get(String userId, {int limit = 10}) async {
    final resp = await _client.get('/api/recommendations',
        queryParams: {'user_id': userId, 'limit': '$limit'});
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = body['recommendations'] as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(Recommendation.fromJson)
        .toList();
  }

  Future<List<Recommendation>> similar(String itemId, {int limit = 10}) async {
    final resp = await _client.get(
        '/api/recommendations/similar/$itemId',
        queryParams: {'limit': '$limit'});
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = body['recommendations'] as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(Recommendation.fromJson)
        .toList();
  }

  Future<List<Recommendation>> popular({int limit = 10, String? category}) async {
    final params = <String, String>{'limit': '$limit'};
    if (category != null) params['category'] = category;
    final resp = await _client.get('/api/recommendations/popular',
        queryParams: params);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = body['recommendations'] as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(Recommendation.fromJson)
        .toList();
  }
}

// ── UsersResource ─────────────────────────────────────────────────────────────

class UsersResource {
  final RecommendAIClient _client;
  const UsersResource(this._client);

  Future<User> create(String userId,
      {Map<String, dynamic> properties = const {}}) async {
    final resp = await _client.post('/api/users', {
      'user_id':    userId,
      'properties': properties,
    });
    return User.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<User> getUser(String userId) async {
    final resp = await _client.get('/api/users/$userId');
    return User.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<User> update(String userId, Map<String, dynamic> properties) async {
    final resp = await _client.put('/api/users/$userId', {
      'properties': properties,
    });
    return User.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> delete(String userId) => _client.delete('/api/users/$userId');
}

// ── ItemsResource ─────────────────────────────────────────────────────────────

class ItemsResource {
  final RecommendAIClient _client;
  const ItemsResource(this._client);

  Future<Item> create(String itemId,
      {Map<String, dynamic> properties = const {}}) async {
    final resp = await _client.post('/api/items', {
      'item_id':    itemId,
      'properties': properties,
    });
    return Item.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<Item> getItem(String itemId) async {
    final resp = await _client.get('/api/items/$itemId');
    return Item.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<Item> update(String itemId, Map<String, dynamic> properties) async {
    final resp = await _client.put('/api/items/$itemId', {
      'properties': properties,
    });
    return Item.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> delete(String itemId) => _client.delete('/api/items/$itemId');

  Future<List<Item>> upsert(List<Map<String, dynamic>> items) async {
    final resp = await _client.post('/api/items/bulk', {'items': items});
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = body['items'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(Item.fromJson).toList();
  }
}

// ── InteractionsResource ──────────────────────────────────────────────────────

class InteractionsResource {
  final RecommendAIClient _client;
  const InteractionsResource(this._client);

  Future<Interaction> create(
    String userId,
    String itemId,
    InteractionType interactionType, {
    double? value,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{
      'user_id':          userId,
      'item_id':          itemId,
      'interaction_type': interactionType.name,
    };
    if (value    != null) body['value']    = value;
    if (metadata != null) body['metadata'] = metadata;
    final resp = await _client.post('/api/interactions', body);
    return Interaction.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }
}
