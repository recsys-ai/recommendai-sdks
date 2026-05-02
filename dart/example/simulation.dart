// example/simulation.dart
//
// RecSys.AI Dart SDK — Movie Streaming Simulation
//
// Starts a dart:io HttpServer mock on port 17899, then runs a 10-step
// simulation using the Dart SDK.
//
// Run:  dart run example/simulation.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:recommendai/recommendai.dart';

const mockPort = 17899;

// ── djb2 hash ─────────────────────────────────────────────────────────────────

int djb2(String s) {
  int h = 5381;
  for (final c in s.codeUnits) {
    h = ((h << 5) + h + c) & 0xFFFFFFFF;
  }
  return h;
}

// ── In-memory state ───────────────────────────────────────────────────────────

final _users        = <String, Map<String, dynamic>>{};
final _items        = <String, Map<String, dynamic>>{};
final _interactions = <Map<String, dynamic>>[];

List<Map<String, dynamic>> _computeRecs(String userId, int limit) {
  final seen = _interactions
      .where((ia) => ia['user_id'] == userId)
      .map((ia) => ia['item_id'] as String)
      .toSet();

  final prefs = (_users[userId]?['properties'] as Map?)?['preferred_genre']?.toString() ?? '';

  final candidates = _items.entries
      .where((e) => !seen.contains(e.key))
      .map((e) {
        final itemId = e.key;
        final props  = (e.value['properties'] as Map?) ?? {};
        final rating = (props['rating'] as num?)?.toDouble() ?? 0.0;
        final genre  = props['genre']?.toString() ?? '';
        var score    = rating / 10.0;
        if (prefs.isNotEmpty && genre == prefs) score += 0.2;
        final hashPart = djb2('$userId$itemId') % 100;
        score = min(score + hashPart / 1000.0, 1.0);
        score = (score * 10000).roundToDouble() / 10000;
        final reason = (prefs.isNotEmpty && genre == prefs)
            ? 'Matches preferred genre: $prefs'
            : 'Highly rated content';
        return <String, dynamic>{
          'item_id':  itemId,
          'score':    score,
          'reason':   reason,
          'metadata': {'title': props['title']},
        };
      })
      .toList()
    ..sort((a, b) =>
        (b['score'] as double).compareTo(a['score'] as double));
  return candidates.take(limit).toList();
}

// ── Mock server ───────────────────────────────────────────────────────────────

Future<void> _jsonResponse(HttpResponse res, int status, Object? body) async {
  res.statusCode = status;
  if (status == 204) {
    await res.close();
    return;
  }
  res.headers.contentType = ContentType.json;
  res.write(jsonEncode(body));
  await res.close();
}

Future<Map<String, dynamic>> _readBody(HttpRequest req) async {
  final bytes = await req.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

Map<String, String> _queryParams(HttpRequest req) =>
    req.uri.queryParameters;

Future<void> _handleRequest(HttpRequest req) async {
  final method = req.method;
  final path   = req.uri.path;
  final parts  = path.split('/').where((p) => p.isNotEmpty).toList();
  // e.g. ['api', 'users'] or ['api', 'users', 'alice']

  try {
    if (parts.length == 2 && parts[0] == 'api' && parts[1] == 'users') {
      if (method == 'POST') {
        final b   = await _readBody(req);
        final uid = b['user_id'] as String;
        final rec = <String, dynamic>{
          'user_id': uid, 'properties': b['properties'],
          'created_at': '2024-01-01T00:00:00Z', 'updated_at': '2024-01-01T00:00:00Z',
        };
        _users[uid] = rec;
        return _jsonResponse(req.response, 201, rec);
      }
    } else if (parts.length == 3 && parts[0] == 'api' && parts[1] == 'users') {
      final uid = parts[2];
      if (method == 'GET') {
        final u = _users[uid];
        return u != null
            ? _jsonResponse(req.response, 200, u)
            : _jsonResponse(req.response, 404, {'detail': 'User not found: $uid'});
      } else if (method == 'PUT') {
        final b = await _readBody(req);
        final u = _users[uid];
        if (u != null) {
          u['properties'] = b['properties'];
          u['updated_at'] = '2024-01-01T00:00:00Z';
          return _jsonResponse(req.response, 200, u);
        }
        return _jsonResponse(req.response, 404, {'detail': 'User not found: $uid'});
      } else if (method == 'DELETE') {
        return _users.remove(uid) != null
            ? _jsonResponse(req.response, 204, null)
            : _jsonResponse(req.response, 404, {'detail': 'User not found: $uid'});
      }
    } else if (parts.length == 2 && parts[0] == 'api' && parts[1] == 'items') {
      if (method == 'POST') {
        final b   = await _readBody(req);
        final iid = b['item_id'] as String;
        final rec = <String, dynamic>{
          'item_id': iid, 'properties': b['properties'],
          'created_at': '2024-01-01T00:00:00Z', 'updated_at': '2024-01-01T00:00:00Z',
        };
        _items[iid] = rec;
        return _jsonResponse(req.response, 201, rec);
      }
    } else if (parts.length == 3 && parts[0] == 'api' && parts[1] == 'items') {
      final iid = parts[2];
      if (method == 'GET') {
        final i = _items[iid];
        return i != null
            ? _jsonResponse(req.response, 200, i)
            : _jsonResponse(req.response, 404, {'detail': 'Item not found: $iid'});
      } else if (method == 'PUT') {
        final b = await _readBody(req);
        final i = _items[iid];
        if (i != null) {
          i['properties'] = b['properties'];
          i['updated_at'] = '2024-01-01T00:00:00Z';
          return _jsonResponse(req.response, 200, i);
        }
        return _jsonResponse(req.response, 404, {'detail': 'Item not found: $iid'});
      } else if (method == 'DELETE') {
        return _items.remove(iid) != null
            ? _jsonResponse(req.response, 204, null)
            : _jsonResponse(req.response, 404, {'detail': 'Item not found: $iid'});
      }
    } else if (parts.length == 2 && parts[0] == 'api' && parts[1] == 'interactions') {
      if (method == 'POST') {
        final b   = await _readBody(req);
        final rec = Map<String, dynamic>.from(b)
          ..['interaction_id'] = 'ia_${DateTime.now().microsecondsSinceEpoch}'
          ..['timestamp']      = '2024-01-01T00:00:00Z';
        _interactions.add(rec);
        return _jsonResponse(req.response, 201, rec);
      }
    } else if (parts.length == 2 && parts[0] == 'api' && parts[1] == 'recommendations') {
      if (method == 'GET') {
        final params = _queryParams(req);
        final uid    = params['user_id'] ?? '';
        final limit  = int.tryParse(params['limit'] ?? '') ?? 10;
        final recs   = _computeRecs(uid, limit);
        return _jsonResponse(req.response, 200, {'user_id': uid, 'recommendations': recs});
      }
    }
  } catch (e) {
    return _jsonResponse(req.response, 500, {'detail': e.toString()});
  }
  return _jsonResponse(req.response, 404, {'detail': 'Not found'});
}

Future<HttpServer> startMockServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, mockPort);
  server.listen(_handleRequest);
  return server;
}

// ── Simulation ─────────────────────────────────────────────────────────────────

void banner(String title) {
  final line = '=' * (title.length + 4);
  print('$line\n= $title =\n$line\n');
}

void step(int n, String title) => print('── Step $n: $title');

Future<void> main() async {
  final server = await startMockServer();
  print('[mock] Server listening on port $mockPort\n');

  final client = RecommendAIClient(
    apiKey:  'sim-api-key',
    baseUrl: 'http://127.0.0.1:$mockPort',
  );

  // Data ─────────────────────────────────────────────────────────────────────

  final movies = [
    ('movie_001', 'The Matrix',               'sci-fi',   1999, 8.7),
    ('movie_002', 'Inception',                'sci-fi',   2010, 8.8),
    ('movie_003', 'Interstellar',             'sci-fi',   2014, 8.6),
    ('movie_004', 'The Dark Knight',          'action',   2008, 9.0),
    ('movie_005', 'Avengers: Endgame',        'action',   2019, 8.4),
    ('movie_006', 'John Wick',                'action',   2014, 7.4),
    ('movie_007', 'The Shawshank Redemption', 'drama',    1994, 9.3),
    ('movie_008', 'Forrest Gump',             'drama',    1994, 8.8),
    ('movie_009', 'Pulp Fiction',             'thriller', 1994, 8.9),
    ('movie_010', 'The Silence of the Lambs', 'thriller', 1991, 8.6),
  ];

  final userList = [
    ('alice', 'Alice Johnson', 'sci-fi',   28),
    ('bob',   'Bob Smith',     'action',   35),
    ('carol', 'Carol White',   'drama',    42),
    ('dave',  'Dave Brown',    'sci-fi',   23),
    ('eve',   'Eve Davis',     'thriller', 31),
  ];

  final iaList = [
    ('alice', 'movie_001', InteractionType.view,     null),
    ('alice', 'movie_002', InteractionType.like,     null),
    ('alice', 'movie_003', InteractionType.purchase, null),
    ('alice', 'movie_001', InteractionType.rating,   9.0),
    ('bob',   'movie_004', InteractionType.view,     null),
    ('bob',   'movie_005', InteractionType.like,     null),
    ('bob',   'movie_006', InteractionType.purchase, null),
    ('bob',   'movie_004', InteractionType.rating,   8.0),
    ('carol', 'movie_007', InteractionType.view,     null),
    ('carol', 'movie_008', InteractionType.like,     null),
    ('carol', 'movie_007', InteractionType.purchase, null),
    ('carol', 'movie_008', InteractionType.rating,   9.0),
    ('dave',  'movie_001', InteractionType.view,     null),
    ('dave',  'movie_002', InteractionType.purchase, null),
    ('dave',  'movie_003', InteractionType.rating,   8.5),
    ('eve',   'movie_009', InteractionType.view,     null),
    ('eve',   'movie_010', InteractionType.like,     null),
    ('eve',   'movie_009', InteractionType.purchase, null),
    ('eve',   'movie_010', InteractionType.rating,   8.0),
    ('alice', 'movie_002', InteractionType.rating,   10.0),
    ('bob',   'movie_006', InteractionType.rating,   7.5),
    ('carol', 'movie_009', InteractionType.view,     null),
    ('dave',  'movie_004', InteractionType.view,     null),
    ('eve',   'movie_002', InteractionType.view,     null),
    ('alice', 'movie_004', InteractionType.view,     null),
  ];

  banner('RecSys.AI Dart SDK — Movie Streaming Simulation');

  // Step 1: seed catalogue
  step(1, 'Seeding Movie Catalogue');
  for (final (id, title, genre, year, rating) in movies) {
    final item = await client.items.create(id,
        properties: {'title': title, 'genre': genre, 'year': year, 'rating': rating});
    print('  Created item: ${item.itemId} (${item.properties['title']})');
  }
  print('  ${movies.length} movies added to catalogue.\n');

  // Step 2: register users
  step(2, 'Registering Users');
  for (final (uid, name, genre, age) in userList) {
    final user = await client.users.create(uid,
        properties: {'name': name, 'age': age, 'preferred_genre': genre});
    print('  Registered: ${user.userId} (${user.properties['name']})');
  }
  print('  ${userList.length} users registered.\n');

  // Step 3: record interactions
  step(3, 'Recording Watch History & Ratings');
  for (final (uid, iid, type, val) in iaList) {
    await client.interactions.create(uid, iid, type, value: val);
  }
  print('  ${iaList.length} interactions recorded.\n');

  // Step 4: recommendations
  step(4, 'Getting Personalised Recommendations');
  for (final (uid, _, _, _) in userList) {
    final recs = await client.recommendations.get(uid, limit: 5);
    print('  Recommendations for $uid:');
    for (var i = 0; i < recs.length; i++) {
      final r     = recs[i];
      final title = r.metadata['title']?.toString() ?? r.itemId;
      print('    ${i + 1}. ${title.padRight(36)} (score: ${r.score.toStringAsFixed(4)})  ${r.reason}');
    }
    print('');
  }

  // Step 5: update item
  step(5, 'Updating Item Metadata');
  final updated = await client.items.update('movie_001', {
    'title': 'The Matrix', 'genre': 'sci-fi',
    'year': 1999, 'rating': 8.7, 'remastered': true,
  });
  print('  Updated movie_001 — remastered: ${updated.properties['remastered']}\n');

  // Step 6: update user
  step(6, 'Updating User Profile');
  final alice = await client.users.update('alice', {
    'name': 'Alice Johnson', 'age': 29,
    'preferred_genre': 'sci-fi', 'subscription': 'premium',
  });
  print('  alice subscription → ${alice.properties['subscription']}\n');

  // Step 7: retrieve item
  step(7, 'Verifying Item Retrieval');
  final retrieved = await client.items.getItem('movie_004');
  print('  Retrieved: ${retrieved.itemId} — ${retrieved.properties['title']} (${retrieved.properties['genre']})\n');

  // Step 8: error handling
  step(8, 'Error Handling Demo');
  try {
    await client.users.getUser('ghost_999');
    print('  ERROR: expected NotFoundException not thrown!\n');
  } on NotFoundException catch (e) {
    print('  Caught NotFoundException: ${e.message}\n');
  }

  // Step 9: cleanup
  step(9, 'Cleanup');
  await client.users.delete('dave');
  print("  Deleted user 'dave'.");
  try {
    await client.users.getUser('dave');
    print("  ERROR: 'dave' should not exist!");
  } on NotFoundException {
    print("  Confirmed: 'dave' no longer exists.");
  }

  print('');
  banner('Simulation complete — all steps passed!');

  client.close();
  await server.close(force: true);
}
