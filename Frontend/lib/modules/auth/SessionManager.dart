import 'package:flutter/foundation.dart';
import '../../core/services/ApiClient.dart';
import '../../core/models/User.dart';

class SessionManager extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  User? _currentUser;
  bool _isAuthenticated = false;
  String? _roleOverride;

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
      notifyListeners();
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password, {String role = 'employee'}) async {
    try {
      final response = await _api.post('/signup', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      final userData = response['user'];
      _currentUser = User.fromJson(userData);
      _isAuthenticated = true;
      _roleOverride = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Signup failed: $e');
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

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _roleOverride = null;
    notifyListeners();
  }
}
