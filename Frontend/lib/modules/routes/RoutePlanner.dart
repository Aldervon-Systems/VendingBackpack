import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/services/ApiClient.dart';

class RoutePlanner extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  String? _restrictedEmployeeId;
  
  RoutePlanner({String? restrictedEmployeeId}) : _restrictedEmployeeId = restrictedEmployeeId {
    loadRoutes();
  }

  void setRestrictedId(String? id) {
    if (_restrictedEmployeeId == id) return;
    _restrictedEmployeeId = id;
    loadRoutes();
  }

  String? get restrictedEmployeeId => _restrictedEmployeeId;

  List<dynamic> _locations = [];
  bool _isLoading = false;

  List<dynamic> get locations => _locations;
  bool get isLoading => _isLoading;
  List<dynamic> _employees = [];
  String? _activeEmployeeId;
  List<dynamic> _activeRouteStops = []; 
  
  // Now stores all routes: map of employeeId -> { color, points }
  final Map<String, dynamic> _allPolylines = {}; 

  List<dynamic> get employees => _employees;
  String? get activeEmployeeId => _activeEmployeeId;
  List<dynamic> get activeRouteStops => _activeRouteStops;
  Map<String, dynamic> get allPolylines => _allPolylines;

  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/routes');
      if (data is Map && data['locations'] is List) {
        _locations = data['locations'];
      }
      await loadEmployees();
      await _fetchAllRoutes(); // Always fetch all routes for background visualization
      
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
      final data = await _api.get('/employees');
      if (data is List) {
        _employees = data;
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }

  void selectEmployee(String? employeeId) {
    _activeEmployeeId = employeeId;
    
    // Reset active stops editor list
    if (employeeId != null && employeeId != 'all') {
       // PRE-POPULATE from cache if available for immediate UI feedback
       if (_allPolylines.containsKey(employeeId) && _allPolylines[employeeId]['stops'] != null) {
         _activeRouteStops = List.from(_allPolylines[employeeId]['stops']);
       } else {
         _activeRouteStops = [];
       }
       notifyListeners();
       _fetchEmployeeRouteStops(employeeId);
    } else {
      _activeRouteStops = [];
      notifyListeners();
    }
  }

  Future<void> _fetchAllRoutes() async {
    try {
      // Use the batch endpoint for efficiency
      final routes = await _api.get('/employees/routes');
      if (routes is List) {
        for (final route in routes) {
          final eid = route['employee_id'].toString();
          final stops = route['stops'] as List?;
          
          if (stops != null && stops.length >= 2) {
             final points = await _fetchOSRMGeometryPoints(stops);
             _allPolylines[eid] = {
               'points': points,
               'stops': stops, // Cache stops for the editor
               'color': _getColorForId(eid)
             };
          } else if (stops != null) {
             // Cache stops even if too short for a polyline
             _allPolylines[eid] = {
               'points': [],
               'stops': stops,
               'color': _getColorForId(eid)
             };
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching all routes: $e');
    }
  }

  Future<void> _fetchEmployeeRouteStops(String employeeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/employees/$employeeId/routes');
      
      if (_activeEmployeeId != employeeId) return;

      dynamic route;
      if (response is List) {
        route = response.isNotEmpty ? response.first : null;
      } else if (response is Map) {
        route = response;
      }

      if (route != null && route['stops'] is List) {
        final stops = route['stops'] as List;
        _activeRouteStops = stops;
        
        if (stops.length >= 2) {
          final points = await _fetchOSRMGeometryPoints(stops);
          if (_activeEmployeeId != employeeId) return;

          _allPolylines[employeeId] = {
             'points': points,
             'stops': stops, // Update cache
             'color': _getColorForId(employeeId)
          };
        } else {
          _allPolylines[employeeId] = {
             'points': [],
             'stops': stops,
             'color': _getColorForId(employeeId)
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching employee route: $e');
    } finally {
      if (_activeEmployeeId == employeeId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> assignMachineToEmployee(String machineId, String employeeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedRoute = await _api.post('/employees/$employeeId/routes/assign', {
        'machine_id': machineId
      });
      
      if (updatedRoute != null && updatedRoute['stops'] is List) {
        final stops = updatedRoute['stops'] as List;
        if (stops.length >= 2) {
           final points = await _fetchOSRMGeometryPoints(stops);
           if (_activeEmployeeId == employeeId) {
             _allPolylines[employeeId] = {
               'points': points,
               'stops': stops,
               'color': _getColorForId(employeeId)
             };
             _activeRouteStops = stops;
           }
        } else {
           if (_activeEmployeeId == employeeId) {
             _allPolylines[employeeId] = {
               'points': [],
               'stops': stops,
               'color': _getColorForId(employeeId)
             };
             _activeRouteStops = stops;
           }
        }
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
      final updatedRoute = await _api.put('/employees/$employeeId/routes/stops', {
        'stop_ids': stopIds,
      });

      if (_activeEmployeeId != employeeId) return;

      if (updatedRoute != null && updatedRoute['stops'] is List) {
        final stops = updatedRoute['stops'] as List;
        if (stops.length >= 2) {
           final points = await _fetchOSRMGeometryPoints(stops);
           
           if (_activeEmployeeId != employeeId) return;

           _allPolylines[employeeId] = {
             'points': points,
             'stops': stops,
             'color': _getColorForId(employeeId)
           };
        } else {
           _allPolylines[employeeId] = {
             'points': [],
             'stops': stops,
             'color': _getColorForId(employeeId)
           };
        }

        if (_activeEmployeeId == employeeId) {
          _activeRouteStops = stops;
        }
      }
    } catch (e) {
      debugPrint('Error updating route stops: $e');
    } finally {
      if (_activeEmployeeId == employeeId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<List<List<double>>> _fetchOSRMGeometryPoints(List<dynamic> stops) async {
    if (stops.length < 2) return [];

    final coordinates = stops.map((s) => '${s['lng']},${s['lat']}').join(';');
    final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson');

    try {
      final response = await _api.client.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body); 
        if (json['routes'] is List && json['routes'].isNotEmpty) {
          final geometry = json['routes'][0]['geometry'];
           if (geometry['coordinates'] is List) {
             return (geometry['coordinates'] as List).map<List<double>>((coord) {
               return [(coord[1] as num).toDouble(), (coord[0] as num).toDouble()];
             }).toList();
           }
        }
      }
    } catch (e) {
       debugPrint('Error fetching OSRM: $e - Falling back to straight lines');
    }
    
    // Fallback
    return stops.map<List<double>>((s) => [
      (s['lat'] as num).toDouble(),
      (s['lng'] as num).toDouble()
    ]).toList();
  }

  Future<void> autogenerateRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.post('/routes/autogenerate', {});
      if (response != null && response['status'] == 'success') {
        // Full reload of routes and stops
        await _fetchAllRoutes();
        
        // If we have an active employee, refresh their sequence
        if (_activeEmployeeId != null && _activeEmployeeId != 'all') {
          if (_allPolylines.containsKey(_activeEmployeeId)) {
            _activeRouteStops = List.from(_allPolylines[_activeEmployeeId]['stops']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error autogenerating routes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _getColorForId(String id) {
    final hash = id.hashCode;
    // Ensure high contrast/brightness
    // Just using a deterministic spread of hues
    return 0xFF000000 | (hash & 0xFFFFFF); 
  }
}
