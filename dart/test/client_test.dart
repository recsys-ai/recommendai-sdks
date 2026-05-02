import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:recommendai/src/client.dart';
import 'package:recommendai/src/exceptions.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

RecommendAIClient _makeClient(
  Future<http.Response> Function(http.Request) handler,
) {
  return RecommendAIClient(
    apiKey: 'test-key',
    baseUrl: 'http://localhost:8080',
    httpClient: MockClient(handler),
  );
}

http.Response _json(Map<String, dynamic> body, {int status = 200}) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

// ---------------------------------------------------------------------------
// ping
// ---------------------------------------------------------------------------

void main() {
  group('ping', () {
    test('returns true when server responds 200', () async {
      final client = _makeClient((_) async => http.Response('', 200));
      expect(await client.ping(), isTrue);
    });

    test('returns false when server responds 503', () async {
      final client =
          _makeClient((_) async => http.Response('', 503));
      expect(await client.ping(), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('recommendations', () {
    test('get() returns a list of recommendations', () async {
      final client = _makeClient((req) async {
        expect(req.url.path, equals('/api/recommendations'));
        expect(req.url.queryParameters['user_id'], equals('user1'));
        return _json({
          'recommendations': [
            {'item_id': 'item1', 'score': 0.9, 'reason': 'test', 'metadata': {}}
          ]
        });
      });
      final recs = await client.recommendations.get('user1', limit: 5);
      expect(recs, hasLength(1));
      expect(recs.first.itemId, equals('item1'));
    });

    test('similar() calls correct endpoint', () async {
      final client = _makeClient((req) async {
        expect(req.url.path, equals('/api/recommendations/similar/item99'));
        expect(req.url.queryParameters['limit'], equals('10'));
        return _json({
          'recommendations': [
            {'item_id': 'item2', 'score': 0.8, 'reason': '', 'metadata': {}}
          ]
        });
      });
      final recs =
          await client.recommendations.similar('item99', limit: 10);
      expect(recs, hasLength(1));
      expect(recs.first.itemId, equals('item2'));
    });

    test('popular() passes category query param', () async {
      final client = _makeClient((req) async {
        expect(req.url.path, equals('/api/recommendations/popular'));
        expect(req.url.queryParameters['category'], equals('books'));
        return _json({
          'recommendations': [
            {'item_id': 'book1', 'score': 0.7, 'reason': '', 'metadata': {}}
          ]
        });
      });
      final recs =
          await client.recommendations.popular(limit: 5, category: 'books');
      expect(recs, hasLength(1));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('items', () {
    test('upsert() posts to /api/items/bulk', () async {
      final client = _makeClient((req) async {
        expect(req.method, equals('POST'));
        expect(req.url.path, equals('/api/items/bulk'));
        return _json({
          'items': [
            {'item_id': 'itemA', 'properties': {}, 'created_at': null, 'updated_at': null}
          ]
        });
      });
      final items = await client.items.upsert([
        {'item_id': 'itemA', 'properties': {'name': 'Book A'}}
      ]);
      expect(items, hasLength(1));
      expect(items.first.itemId, equals('itemA'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('error handling', () {
    test('401 response raises AuthenticationException', () async {
      final client = _makeClient((_) async =>
          _json({'detail': 'invalid api key'}, status: 401));
      expect(
        () => client.recommendations.get('u', limit: 5),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('404 response raises NotFoundException', () async {
      final client = _makeClient(
          (_) async => _json({'detail': 'not found'}, status: 404));
      expect(
        () => client.recommendations.get('u', limit: 5),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('429 response raises RateLimitException', () async {
      final client = _makeClient(
          (_) async => _json({'detail': 'rate limit'}, status: 429));
      expect(
        () => client.recommendations.get('u', limit: 5),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
