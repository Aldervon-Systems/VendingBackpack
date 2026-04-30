import '../contracts/operations.dart';
import '../services/ApiClient.dart';

class DashboardSnapshot {
  final List<MachineInventorySnapshotDto> inventory;
  final List<EmployeeDto> employees;
  final List<DailyStatDto> dailyStats;
  final List<MachineDto> machines;
  final List<RouteDto> routes;
  final RouteDto? userRoute;
  final List<String> failedFeeds;

  DashboardSnapshot({
    required this.inventory,
    required this.employees,
    required this.dailyStats,
    required this.machines,
    required this.routes,
    required this.userRoute,
    required this.failedFeeds,
  });
}

class DashboardRepository {
  final ApiClient _api;

  DashboardRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<DashboardSnapshot> getSnapshot({
    required String role,
    String? userId,
  }) async {
    final failedFeeds = <String>[];
    var inventory = <MachineInventorySnapshotDto>[];
    var employees = <EmployeeDto>[];
    var dailyStats = <DailyStatDto>[];
    var machines = <MachineDto>[];
    var routes = <RouteDto>[];
    RouteDto? userRoute;

    try {
      final data = await _api.get('/inventory');
      inventory = (data as List)
          .whereType<Map>()
          .map((row) => MachineInventorySnapshotDto.fromJson(
              Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      failedFeeds.add('inventory');
    }

    try {
      final data = await _api.get('/employees');
      employees = (data as List)
          .whereType<Map>()
          .map((row) => EmployeeDto.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      failedFeeds.add('employees');
    }

    try {
      final data = await _api.get('/daily_stats');
      dailyStats = (data as List)
          .whereType<Map>()
          .map((row) => DailyStatDto.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      failedFeeds.add('dailyStats');
    }

    try {
      final data = await _api.get('/machines');
      machines = (data as List)
          .whereType<Map>()
          .map((row) => MachineDto.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      failedFeeds.add('machines');
    }

    try {
      if (role == 'manager') {
        final data = await _api.get('/routes');
        routes = (data as List)
            .whereType<Map>()
            .map((row) => RouteDto.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      } else if (userId != null && userId.isNotEmpty) {
        final data = await _api.get('/employees/$userId/routes');
        userRoute = RouteDto.fromJson(Map<String, dynamic>.from(data as Map));
        routes = [userRoute];
      }
    } catch (_) {
      failedFeeds.add('routes');
    }

    return DashboardSnapshot(
      inventory: inventory,
      employees: employees,
      dailyStats: dailyStats,
      machines: machines,
      routes: routes,
      userRoute: userRoute,
      failedFeeds: failedFeeds,
    );
  }

  Future<Map<String, dynamic>> getPreferences() async {
    return Map<String, dynamic>.from(
      await _api.get('/dashboard/preferences') as Map,
    );
  }

  Future<Map<String, dynamic>> savePreferences(
    Map<String, dynamic> preferences,
  ) async {
    return Map<String, dynamic>.from(
      await _api.put('/dashboard/preferences', preferences) as Map,
    );
  }

  Future<void> updateItemQuantity({
    required String machineId,
    required String sku,
    required int quantity,
  }) async {
    await _api.post('/warehouse/update', {
      'machine_id': machineId,
      'sku': sku,
      'quantity': quantity,
    });
  }
}
