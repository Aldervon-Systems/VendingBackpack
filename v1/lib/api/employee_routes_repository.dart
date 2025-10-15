import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'local_data.dart';

import 'employees_store.dart';
import 'employees_repository.dart';
import 'locations_repository.dart';

// Use Employee from employees_repository.dart

@immutable
class EmployeeRoute {
  final String employeeId;
  final String employeeName;
  final Color color;
  final List<VmLocation> stops;
  final List<LatLng> geometry;
  final double distanceMeters;
  final double durationSeconds;

  const EmployeeRoute({
    required this.employeeId,
    required this.employeeName,
    required this.color,
    required this.stops,
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'color': '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'stops': [
          for (final s in stops)
            {'id': s.id, 'name': s.name, 'lat': s.ll.latitude, 'lng': s.ll.longitude}
        ],
        'geometry': [for (final p in geometry) [p.longitude, p.latitude]],
      };

  static EmployeeRoute fromJson(Map<String, dynamic> m) {
    final color = EmployeeRoutesRepository._parseColorOr(m['color']?.toString(), const Color(0xFF1E88E5));
    final stopsJson = (m['stops'] as List? ?? const []).cast<Map<String, dynamic>>();
    final geom = (m['geometry'] as List? ?? const []).cast<List>();
    return EmployeeRoute(
      employeeId: (m['employeeId'] ?? '').toString(),
      employeeName: (m['employeeName'] ?? '').toString(),
      color: color,
      distanceMeters: ((m['distanceMeters'] ?? 0) as num).toDouble(),
      durationSeconds: ((m['durationSeconds'] ?? 0) as num).toDouble(),
      stops: [
        for (final s in stopsJson)
          VmLocation(
            (s['id'] ?? '').toString(),
            (s['name'] ?? '').toString(),
            LatLng(((s['lat'] ?? 0) as num).toDouble(), ((s['lng'] ?? 0) as num).toDouble()),
          )
      ],
      geometry: [
        for (final xy in geom)
          LatLng(((xy[1] ?? 0) as num).toDouble(), ((xy[0] ?? 0) as num).toDouble()),
      ],
    );
  }
}

class EmployeeRoutesRepository {
  static final router = _RouterClient(baseUrl: 'https://router.project-osrm.org');

  // Last generated routes (in-memory) — manager generation writes here and employees can watch.
  static final ValueNotifier<List<EmployeeRoute>?> lastGenerated = ValueNotifier<List<EmployeeRoute>?>(null);
  // Debug: record which host served persisted routes last
  static String? lastLoadedHost;

  static void _setLastGenerated(List<EmployeeRoute> routes) {
    lastGenerated.value = List<EmployeeRoute>.unmodifiable(routes);
  }

  // ---- PUBLIC API -----------------------------------------------------------

  /// Load employees from persistent store; fall back to asset; persist on first success.
  // Always use EmployeesRepository for loading employees
  static Future<List<Employee>> loadEmployees() async {
    final store = EmployeesStore.instance();
    final persisted = await store.read();
    if (persisted != null && persisted.isNotEmpty) {
      final decoded = jsonDecode(persisted);
      if (decoded is List) {
        return decoded.map((e) => Employee.fromJson(e)).toList();
      }
    }
    return [];
  }

  /// Persist employees to platform store.
  // Always use EmployeesRepository for saving employees
  static Future<void> saveEmployees(List<Employee> emps) async {
    await EmployeesRepository.saveEmployees(emps);
  }

  /// Export a pretty JSON that you can commit to the repo when you want.
  /// Web: triggers a browser download.
  /// IO: writes the file into your app support dir and returns the path message.
  // Use EmployeesRepository for exporting employee JSON
  static Future<String?> exportEmployeesJson(List<Employee> emps, {String fileName = 'employees.json'}) async {
    // If EmployeesRepository adds export, use it; otherwise, fallback to EmployeesStore
    final store = EmployeesStore.instance();
    final pretty = const JsonEncoder.withIndent('  ')
        .convert([for (final e in emps) e.toJson()]);
    return store.export(pretty, fileName: fileName);
  }

  /// Generate optimized routes using OSRM /trip, grouping stops by angular sweep.
  static Future<List<EmployeeRoute>> generateOptimized({
    required LatLng homeBase,
    required List<VmLocation> stops,
    required List<Employee> employees,
  }) async {
    if (stops.isEmpty || employees.isEmpty) return const [];

    // 1) Partition by angle around depot
    final entries = stops.map((s) => MapEntry(_angleFrom(homeBase, s.ll), s)).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final per = (entries.length / employees.length).ceil();
    final chunks = <List<VmLocation>>[];
    for (var i = 0; i < entries.length; i += per) {
      chunks.add(entries.sublist(i, math.min(i + per, entries.length))
          .map((e) => e.value).toList());
    }
    while (chunks.length < employees.length) {
      chunks.add(const <VmLocation>[]);
    }

    // 2) Optimize each chunk via OSRM /trip
    final out = <EmployeeRoute>[];
    for (var i = 0; i < employees.length; i++) {
      final emp = employees[i];
      final chunk = i < chunks.length ? chunks[i] : const <VmLocation>[];

      if (chunk.isEmpty) {
        out.add(EmployeeRoute(
          employeeId: emp.id,
          employeeName: emp.name,
          color: emp.color,
          stops: const [],
          geometry: const [],
          distanceMeters: 0,
          durationSeconds: 0,
        ));
        continue;
      }

      final coords = <LatLng>[homeBase, ...chunk.map((s) => s.ll)];

      try {
        final trip = await router.tripRoundtrip(coords);

        // Rebuild ordered stops (exclude depot at index 0)
        final orderedStops = <VmLocation>[];
        for (final idx in trip.order) {
          if (idx == 0) continue;
          final c = coords[idx];
          final found = chunk.firstWhere(
            (s) => s.ll.latitude == c.latitude && s.ll.longitude == c.longitude,
            orElse: () => chunk[math.min(idx - 1, chunk.length - 1)],
          );
          orderedStops.add(found);
        }

        out.add(EmployeeRoute(
          employeeId: emp.id,
          employeeName: emp.name,
          color: emp.color,
          stops: orderedStops,
          geometry: trip.geometry,
          distanceMeters: trip.distanceMeters,
          durationSeconds: trip.durationSeconds,
        ));
      } catch (e, st) {
        debugPrint('[EmployeeRoutesRepository] trip failed for ${emp.id}: $e\n$st');
        final nn = _nearestNeighbor(homeBase, chunk);
        final waypoints = [homeBase, ...nn.map((s) => s.ll), homeBase];
        final geom = await router.routeSnapped(waypoints);
        out.add(EmployeeRoute(
          employeeId: emp.id,
          employeeName: emp.name,
          color: emp.color,
          stops: nn,
          geometry: geom,
          distanceMeters: 0,
          durationSeconds: 0,
        ));
      }
    }
    // Publish last-generated routes so employee views can pick them up.
    _setLastGenerated(out);
    // Persist generated routes to the backend so other clients can load them.
    try {
      persistRoutes(out);
    } catch (_) {}
    return out;
  }

  /// Load persisted routes from the backend and publish them to [lastGenerated].
  static Future<void> loadPersistedRoutes() async {
    try {
      // Try multiple host candidates because the correct host can vary by
      // runtime (web vs emulator vs physical device).
      // Prefer the configured base host first (this mirrors WarehouseApi which
      // evaluates localDataBaseUrl() at import-time). Fall back to loopback
      // hosts afterwards so the behaviour is consistent with the working
      // warehouse/scan flows.
      final candidates = <String>[];
      try {
        final configured = Uri.parse(localDataBaseUrl()).host;
        if (configured.isNotEmpty) candidates.add(configured);
      } catch (_) {}
      // Add loopback fallbacks
      for (final h in ['127.0.0.1', 'localhost']) if (!candidates.contains(h)) candidates.add(h);

      for (final host in candidates) {
        try {
          final uri = Uri.parse('http://$host:5050/employee_routes');
          final resp = await http.get(uri).timeout(const Duration(milliseconds: 2500));
          if (resp.statusCode == 200) {
            final decoded = jsonDecode(resp.body);
            if (decoded is List) {
              final routes = decoded.map((m) => EmployeeRoute.fromJson(m as Map<String, dynamic>)).toList();
              _setLastGenerated(routes);
              lastLoadedHost = host;
              debugPrint('[EmployeeRoutesRepository] loaded ${routes.length} persisted routes from $host');
              return;
            }
          }
        } catch (e) {
          debugPrint('[EmployeeRoutesRepository] host $host failed: $e');
          // try next host
        }
      }
      debugPrint('[EmployeeRoutesRepository] loadPersistedRoutes: no persisted routes found on any host');
    } catch (e) {
      debugPrint('[EmployeeRoutesRepository] loadPersistedRoutes unexpected error: $e');
    }
  }

  static Timer? _pollTimer;
  static bool _pollingStarted = false;

  /// Start periodic polling of persisted routes so already-running clients
  /// will pick up manager-published routes without needing a reload.
  static void startAutoRefresh({Duration interval = const Duration(seconds: 10)}) {
    if (_pollingStarted) return;
    _pollingStarted = true;
    _pollTimer = Timer.periodic(interval, (_) async {
      await loadPersistedRoutes();
    });
  }

  /// Stop polling (not usually necessary in the app lifecycle).
  static void stopAutoRefresh() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingStarted = false;
  }

  /// Persist routes to the backend so other clients (employees) can load them.
  static Future<bool> persistRoutes(List<EmployeeRoute> routes) async {
    final body = jsonEncode([for (final r in routes) r.toJson()]);
    // Try configured host first, then fallbacks (match loadPersistedRoutes order)
    final candidates = <String>[];
    try {
      final configured = Uri.parse(localDataBaseUrl()).host;
      if (configured.isNotEmpty) candidates.add(configured);
    } catch (_) {}
    for (final h in ['127.0.0.1', 'localhost']) if (!candidates.contains(h)) candidates.add(h);

    for (final host in candidates) {
      try {
        final uri = Uri.parse('http://$host:5050/employee_routes');
        final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(milliseconds: 2500));
        if (resp.statusCode == 200) {
          debugPrint('[EmployeeRoutesRepository] persisted routes to $host');
          return true;
        }
      } catch (e) {
        debugPrint('[EmployeeRoutesRepository] persist to $host failed: $e');
      }
    }
    debugPrint('[EmployeeRoutesRepository] persistRoutes: all hosts failed');
    return false;
  }

  // ---- internals ------------------------------------------------------------

  // Removed unused fallback parser

  static double _angleFrom(LatLng origin, LatLng p) {
    final dy = p.latitude - origin.latitude;
    final dx = p.longitude - origin.longitude;
    var a = (dx == 0 && dy == 0) ? 0.0 : (math.atan2(dy, dx) * 180 / math.pi);
    if (a < 0) a += 360;
    return a;
  }

  static List<VmLocation> _nearestNeighbor(LatLng start, List<VmLocation> pts) {
    if (pts.isEmpty) return pts;
    final remaining = List<VmLocation>.from(pts);
    final out = <VmLocation>[];
    var cur = start;
    final distance = const Distance();
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) => distance(cur, a.ll).compareTo(distance(cur, b.ll)));
      final next = remaining.removeAt(0);
      out.add(next);
      cur = next.ll;
    }
    return out;
  }

  static Color _parseColorOr(String? s, Color fallback) {
    if (s == null || s.isEmpty) return fallback;
    try {
      var v = s.toUpperCase().replaceAll('#', '');
      if (v.startsWith('0X')) v = v.substring(2);
      if (v.length == 6) v = 'FF$v';
      final n = int.parse(v, radix: 16);
      return Color(n);
    } catch (_) {
      return fallback;
    }
  }

  // Removed unused palette

  // Removed unused fallback employees
}

// ---------------- OSRM client ----------------

class _TripResult {
  final List<LatLng> geometry;
  final List<int> order;
  final double distanceMeters;
  final double durationSeconds;

  _TripResult(this.geometry, this.order, this.distanceMeters, this.durationSeconds);
}

class _RouterClient {
  final String baseUrl;
  const _RouterClient({required this.baseUrl});

  Future<_TripResult> tripRoundtrip(List<LatLng> coords) async {
    if (coords.length < 2) {
      return _TripResult(coords, List.generate(coords.length, (i) => i), 0, 0);
    }
    final coordStr = coords.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = Uri.parse(
      '$baseUrl/trip/v1/driving/$coordStr'
      '?roundtrip=true&source=first&steps=false&geometries=geojson&overview=full',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw StateError('OSRM trip error ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if ((json['code'] as String?) != 'Ok') {
      throw StateError('OSRM trip failed: ${json['code']}');
    }
    final trips = (json['trips'] as List?) ?? const [];
    if (trips.isEmpty) {
      throw StateError('OSRM trip: no trips returned');
    }
    final trip0 = trips.first as Map<String, dynamic>;
    final geom = (trip0['geometry'] as Map)['coordinates'] as List;
    final geometry = geom.map((xy) => LatLng((xy[1] as num).toDouble(), (xy[0] as num).toDouble())).toList();
    final distance = (trip0['distance'] as num).toDouble();
    final duration = (trip0['duration'] as num).toDouble();

    final waypoints = (json['waypoints'] as List).cast<Map>();
    final orderPairs = <MapEntry<int, int>>[];
    for (var i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final idx = (wp['waypoint_index'] as num?)?.toInt();
      if (idx == null) continue;
      orderPairs.add(MapEntry(i, idx));
    }
    orderPairs.sort((a, b) => a.value.compareTo(b.value));
    final order = orderPairs.map((e) => e.key).toList();
    return _TripResult(geometry, order, distance, duration);
  }

  Future<List<LatLng>> routeSnapped(List<LatLng> points) async {
    if (points.length < 2) return points;
    final coords = points.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = Uri.parse(
      '$baseUrl/route/v1/driving/$coords?overview=full&geometries=geojson&steps=false&annotations=false',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw StateError('OSRM route error ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = decoded['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw StateError('OSRM route: no routes found');
    }
    final geom = routes.first['geometry'] as Map<String, dynamic>;
    final coordsArr = (geom['coordinates'] as List).cast<List>();
    return coordsArr
        .map((xy) => LatLng((xy[1] as num).toDouble(), (xy[0] as num).toDouble()))
        .toList();
  }
}
