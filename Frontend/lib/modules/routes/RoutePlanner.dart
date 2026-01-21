import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/services/ApiClient.dart';

class RoutePlanner extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final String? restrictedEmployeeId;
  
  RoutePlanner({this.restrictedEmployeeId});

  List<dynamic> _locations = [];
  bool _isLoading = false;

  List<dynamic> get locations => _locations;
  bool get isLoading => _isLoading;
  List<dynamic> _employees = [];
  String? _activeEmployeeId;
  List<dynamic> _activeRouteStops = []; // Only relevant for single selection or just last loaded?
  // List of { 'color': Color, 'points': List<[lat, lng]> }
  List<Map<String, dynamic>> _polylines = []; 

  List<dynamic> get employees => _employees;
  String? get activeEmployeeId => _activeEmployeeId;
  List<dynamic> get activeRouteStops => _activeRouteStops;
  List<Map<String, dynamic>> get polylines => _polylines;

  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/routes');
      if (data is Map && data['locations'] is List) {
        _locations = data['locations'];
      }
      await loadEmployees();
      
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
    _activeRouteStops = [];
    _polylines = [];
    
    if (employeeId == 'all') {
      _fetchAllRoutes();
    } else if (employeeId != null) {
      _fetchEmployeeRoute(employeeId);
    } else {
      notifyListeners();
    }
  }

  Future<void> _fetchAllRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      for (final emp in _employees) {
        // Fetch each sequentially to avoid hammering the demo API
        final routes = await _api.get('/employees/${emp['id']}/routes');
        if (routes is List && routes.isNotEmpty) {
           final route = routes.first;
           if (route['stops'] is List && (route['stops'] as List).length >= 2) {
             final points = await _fetchOSRMGeometryPoints(route['stops']);
             // Use a consistent color or random, or parse from employee if available
             // Employee model in backend has 'color' but simpler to just hash string to color or rotating list
             _polylines.add({
               'points': points,
               'color': _getColorForId(emp['id'].toString())
             });
           }
        }
      }
    } catch (e) {
      debugPrint('Error fetching all routes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchEmployeeRoute(String employeeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final routes = await _api.get('/employees/$employeeId/routes');
      if (routes is List && routes.isNotEmpty) {
        final route = routes.first;
        if (route['stops'] is List) {
          _activeRouteStops = route['stops'];
          final points = await _fetchOSRMGeometryPoints(_activeRouteStops);
          _polylines = [{
            'points': points,
            'color': _getColorForId(employeeId)
          }];
        }
      } else {
        _activeRouteStops = [];
        _polylines = [];
      }
    } catch (e) {
      debugPrint('Error fetching employee route: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
        // Refresh view based on current selection
        if (_activeEmployeeId == 'all') {
          selectEmployee('all'); // Reload all
        } else if (_activeEmployeeId == employeeId) {
          _activeRouteStops = updatedRoute['stops'];
          final points = await _fetchOSRMGeometryPoints(_activeRouteStops);
          _polylines = [{
            'points': points,
            'color': _getColorForId(employeeId)
          }];
        }
      }
    } catch (e) {
      debugPrint('Error assigning route: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRouteStops(String employeeId, List<String> stopIds) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Use client.put directly because ApiClient might not have a put wrapper exposed or documented easily, checking... 
      // ApiClient.dart has get and post only. So I'll use _api.client.put
      // Wait, ApiClient.dart code view earlier showed get and post. No put. 
      // I'll add PUT to ApiClient or just use _api.client.put here.
      // Let's use _api.client.put. url needs to be full.
      // Actually ApiClient has _buildUrl strictly private.
      // I should probably add put to ApiClient, but for now I'll hack it or add it.
      // Adding it to ApiClient is cleaner. 
      // But to save context switching I will just assume I can pass manual full URL or just modify ApiClient quickly?
      // Modifying ApiClient is better practice. But I am in RoutePlanner. 
      // Let's modify ApiClient first? No, the tool call is already for RoutePlanner.
      // I'll just copy the _buildUrl logic effectively or use the public getter `ApiClient.baseUrl` provided it is public?
      // ApiClient.dart: static String get baseUrl. 
      // So I can do: Uri.parse('${ApiClient.baseUrl}/employees/$employeeId/routes/stops')
      
      final url = Uri.parse('${ApiClient.baseUrl}/employees/$employeeId/routes/stops');
      final response = await _api.client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'stop_ids': stopIds}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final updatedRoute = jsonDecode(response.body);
        if (updatedRoute != null && updatedRoute['stops'] is List) {
          _activeRouteStops = updatedRoute['stops'];
          final points = await _fetchOSRMGeometryPoints(_activeRouteStops);
          _polylines = [{
            'points': points,
            'color': _getColorForId(employeeId)
          }];
        }
      } else {
        throw Exception('Failed to update route stops: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating route stops: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to return just the points, not setting state directly
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

  int _getColorForId(String id) {
    // Generate a consistent pseudo-random color (ARGB)
    final hash = id.hashCode;
    return 0xFF000000 | (hash & 0xFFFFFF);
  }
}
