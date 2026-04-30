import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/contracts/operations.dart';
import '../../core/repositories/routes_repository.dart';
import '../../core/services/ApiClient.dart';

class RoutePlanner extends ChangeNotifier {
  final RoutesRepository _repository = RoutesRepository();
  String? _restrictedEmployeeId;

  RoutePlanner({String? restrictedEmployeeId})
      : _restrictedEmployeeId = restrictedEmployeeId {
    loadRoutes();
  }

  String? get restrictedEmployeeId => _restrictedEmployeeId;

  List<MachineDto> _locations = [];
  bool _isLoading = false;
  List<EmployeeDto> _employees = [];
  String? _activeEmployeeId;
  List<RouteStopDto> _activeRouteStops = [];
  final Map<String, dynamic> _allPolylines = {};

  List<MachineDto> get locations => _locations;
  bool get isLoading => _isLoading;
  List<EmployeeDto> get employees => _employees;
  String? get activeEmployeeId => _activeEmployeeId;
  List<RouteStopDto> get activeRouteStops => _activeRouteStops;
  Map<String, dynamic> get allPolylines => _allPolylines;

  void setRestrictedId(String? id) {
    if (_restrictedEmployeeId == id) return;
    _restrictedEmployeeId = id;
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _locations = await _repository.getMachines();
      await loadEmployees();
      await _fetchAllRoutes();
      if (restrictedEmployeeId != null) {
        selectEmployee(restrictedEmployeeId);
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEmployees() async {
    try {
      _employees = await _repository.getEmployees();
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }

  void selectEmployee(String? employeeId) {
    _activeEmployeeId = employeeId;
    if (employeeId != null && employeeId != 'all') {
      final cachedStops = _allPolylines[employeeId]?['stops'];
      _activeRouteStops = cachedStops is List<RouteStopDto>
          ? List<RouteStopDto>.from(cachedStops)
          : [];
      notifyListeners();
      _fetchEmployeeRouteStops(employeeId);
      return;
    }
    _activeRouteStops = [];
    notifyListeners();
  }

  Future<void> _fetchAllRoutes() async {
    try {
      final routes = await _repository.getRoutes();
      _allPolylines.clear();
      for (final route in routes) {
        await _cacheRoute(route);
      }
    } catch (e) {
      debugPrint('Error fetching all routes: $e');
    }
  }

  Future<void> _fetchEmployeeRouteStops(String employeeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final route = await _repository.getEmployeeRoute(employeeId);
      if (_activeEmployeeId != employeeId) return;
      await _cacheRoute(route);
      _activeRouteStops = route.stops;
    } catch (e) {
      debugPrint('Error fetching employee route: $e');
    } finally {
      if (_activeEmployeeId == employeeId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> assignMachineToEmployee(
    String machineId,
    String employeeId,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.assignMachine(
        machineId: machineId,
        employeeId: employeeId,
      );
      final route = await _repository.getEmployeeRoute(employeeId);
      await _cacheRoute(route);
      if (_activeEmployeeId == employeeId) {
        _activeRouteStops = route.stops;
      }
    } catch (e) {
      debugPrint('Error assigning route: $e');
    } finally {
      if (_activeEmployeeId == employeeId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateRouteStops(String employeeId, List<String> stopIds) async {
    _isLoading = true;
    notifyListeners();
    try {
      final route = await _repository.updateStops(
        employeeId: employeeId,
        stopIds: stopIds,
      );
      if (_activeEmployeeId != employeeId) return;
      await _cacheRoute(route);
      _activeRouteStops = route.stops;
    } catch (e) {
      debugPrint('Error updating route stops: $e');
    } finally {
      if (_activeEmployeeId == employeeId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> autogenerateRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.autogenerateRoutes();
      await _fetchAllRoutes();
      if (_activeEmployeeId != null && _activeEmployeeId != 'all') {
        final cachedStops = _allPolylines[_activeEmployeeId]?['stops'];
        _activeRouteStops = cachedStops is List<RouteStopDto>
            ? List<RouteStopDto>.from(cachedStops)
            : [];
      }
    } catch (e) {
      debugPrint('Error autogenerating routes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cacheRoute(RouteDto route) async {
    final points = route.stops.length >= 2
        ? await _fetchOSRMGeometryPoints(route.stops)
        : <List<double>>[];
    _allPolylines[route.employeeId] = {
      'points': points,
      'stops': route.stops,
      'color': _getColorForId(route.employeeId),
    };
  }

  Future<List<List<double>>> _fetchOSRMGeometryPoints(
    List<RouteStopDto> stops,
  ) async {
    if (stops.length < 2) return [];
    final coordinates =
        stops.map((stop) => '${stop.lng},${stop.lat}').join(';');
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson',
    );

    try {
      final response = await ApiClient().client.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['routes'] is List && json['routes'].isNotEmpty) {
          final geometry = json['routes'][0]['geometry'];
          if (geometry['coordinates'] is List) {
            return (geometry['coordinates'] as List).map<List<double>>((coord) {
              return [
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              ];
            }).toList();
          }
        }
      }
    } catch (_) {}

    return stops.map<List<double>>((stop) => [stop.lat, stop.lng]).toList();
  }

  int _getColorForId(String id) {
    final hash = id.hashCode;
    return 0xFF000000 | (hash & 0xFFFFFF);
  }
}

