import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ApiClient.dart';
import '../../core/models/User.dart';

class SessionManager extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  static const String _tokenStorageKey = 'auth_access_token';
  static const String _userStorageKey = 'auth_user_json';
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isAdminVerified = false;
  bool _isRestoring = true;
  String? _roleOverride;

  SessionManager() {
    _restoreSession();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdminVerified => _isAdminVerified;
  bool get isRestoring => _isRestoring;

  String get actualRole =>
      (_currentUser?.role ?? 'employee').toLowerCase().trim();
  String get effectiveRole {
    if (actualRole == 'manager' && _roleOverride == 'employee') {
      return 'employee';
    }
    return actualRole;
  }

  bool get isManager => actualRole == 'manager';
  bool get isInEmployeeView => effectiveRole != 'manager';

  Future<void> login(
    String email,
    String password, {
    String? organizationId,
  }) async {
    try {
      final response = await _api.post('/token', {
        'email': email,
        'password': password,
        'organization_id': organizationId,
      });

      final accessToken = response['access_token']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication failed: missing access token');
      }
      ApiClient.setAccessToken(accessToken);

      final userData = response['user'];
      _currentUser = User.fromJson(userData);
      _isAuthenticated = true;
      _roleOverride = null;
      await _persistSession(accessToken: accessToken, user: _currentUser!);
      notifyListeners();
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  Future<void> signup(
    String name,
    String email,
    String password, {
    String role = 'employee',
    String? organizationId,
  }) async {
    try {
      final response = await _api.post('/signup', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'organization_id': organizationId,
      });

      final accessToken = response['access_token']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Signup failed: missing access token');
      }
      ApiClient.setAccessToken(accessToken);

      final userData = response['user'];
      _currentUser = User.fromJson(userData);
      _isAuthenticated = true;
      _roleOverride = null;
      await _persistSession(accessToken: accessToken, user: _currentUser!);
      notifyListeners();
    } catch (e) {
      debugPrint('Signup failed: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchOrganizations(String query) async {
    final response = await _api.get('/organizations/search?q=$query');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createOrganization({
    required String name,
    required String managerEmail,
    required String managerPassword,
    required String adminPassword,
    required List<String> whitelist,
  }) async {
    return await _api.post('/organizations/create', {
      'name': name,
      'manager_email': managerEmail,
      'manager_password': managerPassword,
      'admin_password': adminPassword,
      'whitelist': whitelist,
    });
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
    final verified = response['verified'] == true;
    if (verified) {
      _isAdminVerified = true;
      notifyListeners();
    }
    return verified;
  }

  void setEmployeeView(bool enabled) {
    if (!isManager) {
      if (_roleOverride != null) {
        _roleOverride = null;
        notifyListeners();
      }
      return;
    }

    final nextOverride = enabled ? 'employee' : null;
    if (_roleOverride == nextOverride) return;
    _roleOverride = nextOverride;
    notifyListeners();
  }

  Future<void> updateWhitelist(List<String> emails) async {
    final orgId = _currentUser?.organizationId;
    if (orgId == null) throw Exception('No organization linked to user');
    await _api.post('/organizations/$orgId/whitelist', {'emails': emails});
  }

  Future<void> addMachine({
    required String vin,
    required String name,
    required double lat,
    required double lng,
  }) async {
    final orgId = _currentUser?.organizationId;
    if (orgId == null) throw Exception('No organization linked to user');
    await _api.post('/organizations/$orgId/machines', {
      'vin': vin,
      'name': name,
      'lat': lat,
      'lng': lng,
    });
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _isAdminVerified = false;
    _roleOverride = null;
    ApiClient.clearAccessToken();
    _clearPersistedSession();
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenStorageKey);
      final userJson = prefs.getString(_userStorageKey);
      if (token != null &&
          token.isNotEmpty &&
          userJson != null &&
          userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          ApiClient.setAccessToken(token);
          _currentUser = User.fromJson(decoded);
          _isAuthenticated = true;
        } else {
          await _clearPersistedSession();
        }
      }
    } catch (e) {
      debugPrint('Session restore failed: $e');
      await _clearPersistedSession();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _persistSession({
    required String accessToken,
    required User user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenStorageKey, accessToken);
    await prefs.setString(_userStorageKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
    await prefs.remove(_userStorageKey);
  }
}
