import 'dart:convert';
import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'models.dart';
import 'resources.dart';

class RecommendAIClient {
  final String apiKey;
  final String baseUrl;
  final Duration timeout;
  late final http.Client _http;

  late final RecommendationsResource recommendations;
  late final UsersResource             users;
  late final ItemsResource             items;
  late final InteractionsResource      interactions;

  RecommendAIClient({
    required this.apiKey,
    this.baseUrl = 'http://localhost:8080',
    this.timeout = const Duration(seconds: 30),
    http.Client? httpClient,
  }) {
    _http = httpClient ?? http.Client();
    recommendations = RecommendationsResource(this);
    users           = UsersResource(this);
    items           = ItemsResource(this);
    interactions    = InteractionsResource(this);
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type':  'application/json',
    'User-Agent':    'recommendai-dart/1.0.0',
  };

  Future<http.Response> get(String path,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParams?.isEmpty == false ? queryParams : null);
    final resp = await _http.get(uri, headers: _headers).timeout(timeout);
    _checkStatus(resp);
    return resp;
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final uri  = Uri.parse('$baseUrl$path');
    final resp = await _http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    _checkStatus(resp);
    return resp;
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final uri  = Uri.parse('$baseUrl$path');
    final resp = await _http
        .put(uri, headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    _checkStatus(resp);
    return resp;
  }

  Future<void> delete(String path) async {
    final uri  = Uri.parse('$baseUrl$path');
    final resp = await _http.delete(uri, headers: _headers).timeout(timeout);
    _checkStatus(resp);
  }

  void _checkStatus(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    String detail = resp.body;
    try {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      detail = decoded['detail']?.toString() ?? resp.body;
    } catch (_) {}
    throw switch (resp.statusCode) {
      401 => AuthenticationException(detail),
      404 => NotFoundException(detail),
      422 => ValidationException(detail),
      429 => RateLimitException(detail),
      _   => ServerException(detail, statusCode: resp.statusCode),
    };
  }

  Future<bool> ping() async {
    try {
      final uri  = Uri.parse('$baseUrl/health');
      final resp = await _http.get(uri, headers: _headers).timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void close() => _http.close();
}
