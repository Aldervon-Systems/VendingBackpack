import 'package:flutter/foundation.dart';
import 'dart:ui';
import '../../core/models/Employee.dart';
import '../../core/contracts/operations.dart';
import '../../core/repositories/dashboard_repository.dart';

class BusinessMetrics extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();
  bool _isLoading = false;
  List<Employee> _employees = [];
  List<MachineInventorySnapshotDto> _inventory = [];
  List<MachineDto> _machines = [];
  List<RouteDto> _routes = [];
  List<DailyStatDto> _dailyStats = [];
  List<String> _failedFeeds = [];
  double _revenueToday = 0.0;

  bool get isLoading => _isLoading;
  List<Employee> get employees => _employees;
  List<MachineInventorySnapshotDto> get inventory => _inventory;
  List<MachineDto> get machines => _machines;
  List<RouteDto> get routes => _routes;
  List<String> get failedFeeds => _failedFeeds;
  double get revenueToday => _revenueToday;
  int get totalMachines => _machines.isNotEmpty ? _machines.length : _inventory.length;
  int get onlineMachines => _machines.where((machine) => machine.status != 'attention').length;

  Future<void> loadData({String role = 'employee', String? userId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _repository.getSnapshot(role: role, userId: userId);
      _inventory = snapshot.inventory;
      _employees = snapshot.employees
          .map(
            (employee) => Employee(
              id: employee.id,
              name: employee.name,
              color: Color(employee.color ?? 0xFF4A5568),
            ),
          )
          .toList();
      _dailyStats = snapshot.dailyStats;
      _machines = snapshot.machines;
      _routes = snapshot.routes;
      _userMachineIds = snapshot.userRoute?.stops
              .map((stop) => stop.machineId)
              .toList() ??
          [];
      _failedFeeds = snapshot.failedFeeds;
      _revenueToday = _dailyStats.isNotEmpty ? _dailyStats.last.amount : 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Employee Specific Logic ---
  List<String> _userMachineIds = [];
  List<String> get userMachineIds => _userMachineIds;

  Future<void> fetchUserRoute(String userId) async {
    RouteDto? route;
    for (final candidate in _routes) {
      if (candidate.employeeId == userId) {
        route = candidate;
        break;
      }
    }
    _userMachineIds = route?.stops.map((stop) => stop.machineId).toList() ?? [];
    notifyListeners();
  }

  Future<void> updateItemQuantity(
    String machineId,
    String sku,
    int newQty,
  ) async {
    try {
      await _repository.updateItemQuantity(
        machineId: machineId,
        sku: sku,
        quantity: newQty,
      );
      await loadData();
    } catch (e) {
      debugPrint('Error updating item qty: $e');
      await loadData();
    }
  }
}
