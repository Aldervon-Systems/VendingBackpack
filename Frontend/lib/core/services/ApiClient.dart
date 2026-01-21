import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _defaultNonWebBaseUrl = 'http://localhost:9090/api';
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kIsWeb) return '/api';
    return _defaultNonWebBaseUrl;
  }
  final http.Client client;

  ApiClient({http.Client? client}) : client = client ?? http.Client();

  Future<dynamic> get(String endpoint) async {
    final response = await client.get(Uri.parse(_buildUrl(endpoint)));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await client.post(
      Uri.parse(_buildUrl(endpoint)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
     if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to post data: ${response.statusCode}');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await client.put(
      Uri.parse(_buildUrl(endpoint)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
     if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to put data: ${response.statusCode}');
    }
  }

  String _buildUrl(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$normalizedBase$normalizedEndpoint';
  }
}
