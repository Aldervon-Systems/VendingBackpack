import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ApiClient.dart';
import '../../core/models/User.dart';

class SessionManager extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  User? _currentUser;
  bool _isAuthenticated = false;
  String? _roleOverride;

  SessionManager() {
    _loadSession();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  String get actualRole => (_currentUser?.role ?? 'employee').toLowerCase().trim();
  String get effectiveRole {
    if (actualRole == 'manager' && _roleOverride == 'employee') {
      return 'employee';
    }
    return actualRole;
  }

  bool get isManager => actualRole == 'manager';
  bool get isInEmployeeView => effectiveRole != 'manager';

  static const String _userKey = 'vbp_user';
  static const String _timeKey = 'vbp_login_time';
  static const int _sessionExpiryMs = 30 * 60 * 1000; // 30 minutes

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final loginTime = prefs.getInt(_timeKey);

      debugPrint('[Session] Loading: user=$userJson, time=$loginTime');

      if (userJson != null && loginTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - loginTime < _sessionExpiryMs) {
          _currentUser = User.fromJson(jsonDecode(userJson));
          _isAuthenticated = true;
          debugPrint('[Session] Authenticated: ${_currentUser?.name}');
          notifyListeners();
        } else {
          debugPrint('[Session] Expired focal window');
          await logout();
        }
      } else {
        debugPrint('[Session] No stored session found');
      }
    } catch (e) {
      debugPrint('Error loading persistent session: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _api.post('/token', {
        'email': email,
        'password': password,
      });
      
      final userData = response['user'];
      _currentUser = User.fromJson(userData);
      _isAuthenticated = true;
      _roleOverride = null;

      debugPrint('[Session] Login Success: ${_currentUser?.name}');

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      await prefs.setInt(_timeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('[Session] Saved to storage');

      notifyListeners();
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
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

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _roleOverride = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_timeKey);
    
    notifyListeners();
  }
}
