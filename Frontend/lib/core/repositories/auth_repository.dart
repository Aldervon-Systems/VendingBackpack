import '../models/User.dart';
import '../services/ApiClient.dart';

class AuthSession {
  final String accessToken;
  final User user;

  AuthSession({required this.accessToken, required this.user});
}

class AuthRepository {
  final ApiClient _api;

  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<AuthSession> login({
    required String email,
    required String password,
    String? organizationId,
  }) async {
    final response = await _api.post('/token', {
      'email': email,
      'password': password,
      'organization_id': organizationId,
    });

    final token = response['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication failed: missing access token');
    }

    final user =
        User.fromJson(Map<String, dynamic>.from(response['user'] as Map));
    ApiClient.setAccessToken(token);
    return AuthSession(accessToken: token, user: user);
  }

  Future<AuthSession> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? organizationId,
  }) async {
    final response = await _api.post('/signup', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'organization_id': organizationId,
    });

    final token = response['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Signup failed: missing access token');
    }

    final user =
        User.fromJson(Map<String, dynamic>.from(response['user'] as Map));
    ApiClient.setAccessToken(token);
    return AuthSession(accessToken: token, user: user);
  }

  Future<User> me() async {
    final response = await _api.get('/me');
    return User.fromJson(Map<String, dynamic>.from(response['user'] as Map));
  }

  Future<List<Map<String, dynamic>>> searchOrganizations(String query) async {
    final response = await _api
        .get('/organizations/search?q=${Uri.encodeQueryComponent(query)}');
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<Map<String, dynamic>> createOrganization({
    required String name,
    required String managerEmail,
    required String managerPassword,
    required String adminPassword,
    required List<String> whitelist,
  }) {
    return _api.post('/organizations/create', {
      'name': name,
      'manager_email': managerEmail,
      'manager_password': managerPassword,
      'admin_password': adminPassword,
      'whitelist': whitelist,
    }).then((value) => Map<String, dynamic>.from(value as Map));
  }

  Future<bool> verifyAdmin({
    required String organizationId,
    required String adminPassword,
    required String totpCode,
  }) async {
    final response = await _api.post('/organizations/verify_admin', {
      'organization_id': organizationId,
      'admin_password': adminPassword,
      'totp_code': totpCode,
    });
    return response['verified'] == true;
  }

  Future<void> updateWhitelist(String organizationId, List<String> emails) async {
    await _api.post('/organizations/$organizationId/whitelist', {
      'emails': emails,
    });
  }

  Future<void> addMachine({
    required String organizationId,
    required String vin,
    required String name,
    required double lat,
    required double lng,
  }) async {
    await _api.post('/organizations/$organizationId/machines', {
      'vin': vin,
      'name': name,
      'lat': lat,
      'lng': lng,
    });
  }
}

