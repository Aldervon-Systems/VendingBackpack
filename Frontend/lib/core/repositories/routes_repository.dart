import '../contracts/operations.dart';
import '../services/ApiClient.dart';

class RoutesRepository {
  final ApiClient _api;

  RoutesRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<MachineDto>> getMachines() async {
    final data = await _api.get('/machines');
    return (data as List)
        .whereType<Map>()
        .map((row) => MachineDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<EmployeeDto>> getEmployees() async {
    final data = await _api.get('/employees');
    return (data as List)
        .whereType<Map>()
        .map((row) => EmployeeDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<RouteDto>> getRoutes() async {
    final data = await _api.get('/routes');
    return (data as List)
        .whereType<Map>()
        .map((row) => RouteDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<RouteDto> getEmployeeRoute(String employeeId) async {
    final data = await _api.get('/employees/$employeeId/routes');
    return RouteDto.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> autogenerateRoutes() async {
    await _api.post('/routes/autogenerate', {});
  }

  Future<void> assignMachine({
    required String machineId,
    required String employeeId,
  }) async {
    await _api.post('/employees/$employeeId/routes/assign', {
      'machineId': machineId,
    });
  }

  Future<RouteDto> updateStops({
    required String employeeId,
    required List<String> stopIds,
  }) async {
    final data = await _api.put('/employees/$employeeId/routes/stops', {
      'stop_ids': stopIds,
    });
    return RouteDto.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

