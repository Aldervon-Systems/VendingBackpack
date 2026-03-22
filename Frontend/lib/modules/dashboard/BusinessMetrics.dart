import 'package:flutter/foundation.dart';
import '../../core/models/Employee.dart';
import '../../core/services/ApiClient.dart';

class BusinessMetrics extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  bool _isLoading = false;
  List<Employee> _employees = [];
  Map<String, List<dynamic>> _inventory = {};
  List<dynamic> _dailyStats = [];
  double _revenueToday = 0.0;

  bool get isLoading => _isLoading;
  List<Employee> get employees => _employees;
  Map<String, List<dynamic>> get inventory => _inventory;
  double get revenueToday => _revenueToday;
  int get totalMachines => _inventory.keys.length;
  // Mock logic: assume all machines with inventory are online for now
  int get onlineMachines => _inventory.keys.length;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final inv = await _api.get('/inventory');
      if (inv is Map) {
        _inventory = Map<String, List<dynamic>>.from(inv);
      }
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    }

    try {
      final emps = await _api.get('/employees');
      if (emps is List) {
        _employees = emps.map((e) => Employee.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }

    try {
      final stats = await _api.get('/daily_stats');
      if (stats is List) {
        _dailyStats = stats;
        // Simple mock calc: just sum up everything for "today" or take the last entry
        if (_dailyStats.isNotEmpty) {
          _revenueToday = (_dailyStats.last['amount'] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Error loading daily stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Employee Specific Logic ---
  List<String> _userMachineIds = [];
  List<String> get userMachineIds => _userMachineIds;

  Future<void> fetchUserRoute(String userId) async {
    try {
      final routeData = await _api.get('/employees/$userId/routes');
      if (routeData is Map && routeData['stops'] is List) {
        _userMachineIds = (routeData['stops'] as List)
            .map((s) => s['id'].toString())
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user route: $e');
    }
  }

  Future<void> updateItemQuantity(
    String machineId,
    String sku,
    int newQty,
  ) async {
    try {
      await _api.post('/warehouse/update', {
        'machine_id': machineId,
        'sku': sku,
        'quantity': newQty,
      });
      await loadData();
    } catch (e) {
      debugPrint('Error updating item qty: $e');
      await loadData();
    }
  }
}
