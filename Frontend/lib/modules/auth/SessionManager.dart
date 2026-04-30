import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ApiClient.dart';
import '../../core/models/User.dart';
import '../../core/repositories/auth_repository.dart';

class SessionManager extends ChangeNotifier {
  static bool disableCliSessionImportForTests = false;

  final AuthRepository _authRepository = AuthRepository();
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
      final session = await _authRepository.login(
        email: email,
        password: password,
        organizationId: organizationId,
      );
      _currentUser = session.user;
      _isAuthenticated = true;
      _roleOverride = null;
      await _persistSession(accessToken: session.accessToken, user: _currentUser!);
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
      final session = await _authRepository.signup(
        name: name,
        email: email,
        password: password,
        role: role,
        organizationId: organizationId,
      );
      _currentUser = session.user;
      _isAuthenticated = true;
      _roleOverride = null;
      await _persistSession(accessToken: session.accessToken, user: _currentUser!);
      notifyListeners();
    } catch (e) {
      debugPrint('Signup failed: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchOrganizations(String query) async {
    return _authRepository.searchOrganizations(query);
  }

  Future<Map<String, dynamic>> createOrganization({
    required String name,
    required String managerEmail,
    required String managerPassword,
    required String adminPassword,
    required List<String> whitelist,
  }) async {
    return _authRepository.createOrganization(
      name: name,
      managerEmail: managerEmail,
      managerPassword: managerPassword,
      adminPassword: adminPassword,
      whitelist: whitelist,
    );
  }

  Future<bool> verifyAdmin({
    required String organizationId,
    required String adminPassword,
    required String totpCode,
  }) async {
    final verified = await _authRepository.verifyAdmin(
      organizationId: organizationId,
      adminPassword: adminPassword,
      totpCode: totpCode,
    );
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
    await _authRepository.updateWhitelist(orgId, emails);
  }

  Future<void> addMachine({
    required String vin,
    required String name,
    required double lat,
    required double lng,
  }) async {
    final orgId = _currentUser?.organizationId;
    if (orgId == null) throw Exception('No organization linked to user');
    await _authRepository.addMachine(
      organizationId: orgId,
      vin: vin,
      name: name,
      lat: lat,
      lng: lng,
    );
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
      } else {
        await _restoreCliSessionIfPresent(prefs);
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

  Future<void> _restoreCliSessionIfPresent(SharedPreferences prefs) async {
    if (disableCliSessionImportForTests) return;
    if (kIsWeb) return;
    if (Platform.environment['FLUTTER_TEST'] == 'true') return;
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return;
    final surfaceFile = File('$home/.vending-backpack/surface-control.json');
    if (!await surfaceFile.exists()) return;
    final surfacePayload = jsonDecode(await surfaceFile.readAsString());
    if (surfacePayload is! Map<String, dynamic> ||
        surfacePayload['importSession'] != true) {
      return;
    }
    final file = File('$home/.vending-backpack/session.json');
    if (!await file.exists()) return;
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    final accessToken = decoded['access_token']?.toString();
    final userJson = decoded['user'];
    if (accessToken == null || accessToken.isEmpty || userJson is! Map<String, dynamic>) {
      return;
    }
    ApiClient.setAccessToken(accessToken);
    _currentUser = User.fromJson(userJson);
    _isAuthenticated = true;
    await prefs.setString(_tokenStorageKey, accessToken);
    await prefs.setString(_userStorageKey, jsonEncode(_currentUser!.toJson()));
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
    await prefs.remove(_userStorageKey);
  }
}
