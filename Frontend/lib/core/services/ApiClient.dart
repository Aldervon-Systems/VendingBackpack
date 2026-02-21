import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _defaultNonWebBaseUrl = 'http://localhost:9090/api';
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static String? _accessToken;

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kIsWeb) return '/api';
    return _defaultNonWebBaseUrl;
  }

  static void setAccessToken(String? token) {
    _accessToken = token;
  }

  static void clearAccessToken() {
    _accessToken = null;
  }

  final http.Client client;

  ApiClient({http.Client? client}) : client = client ?? http.Client();

  Future<dynamic> get(String endpoint) async {
    final response = await client.get(
      Uri.parse(_buildUrl(endpoint)),
      headers: _headers(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final detail = _parseError(response);
      throw Exception('CMD API_GET FAIL endpoint=$endpoint status=${response.statusCode} detail=$detail');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await client.post(
      Uri.parse(_buildUrl(endpoint)),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
     if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final detail = _parseError(response);
      throw Exception('CMD API_POST FAIL endpoint=$endpoint status=${response.statusCode} detail=$detail');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await client.put(
      Uri.parse(_buildUrl(endpoint)),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
     if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final detail = _parseError(response);
      throw Exception('CMD API_PUT FAIL endpoint=$endpoint status=${response.statusCode} detail=$detail');
    }
  }

  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final detail = data['detail'] ?? data['error'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }
      final rawBody = response.body.toString().trim();
      if (rawBody.isNotEmpty) {
        return rawBody;
      }
      return 'Server error: ${response.statusCode}';
    } catch (_) {
      final rawBody = response.body.toString().trim();
      if (rawBody.isNotEmpty) {
        return rawBody;
      }
      return 'Server error: ${response.statusCode}';
    }
  }

  String _buildUrl(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$normalizedBase$normalizedEndpoint';
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
