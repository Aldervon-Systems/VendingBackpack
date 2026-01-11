import 'dart:async';
import 'package:flutter/gestures.dart'; // PointerHoverEvent
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../api/locations_repository.dart';
import 'package:url_launcher/url_launcher.dart';
// Remove Employee import from employee_routes_repository.dart to avoid type mismatch
// Only import Employee from employees_repository.dart
import '../api/employees_repository.dart';
import '../api/employee_routes_repository.dart';

class RoutesPage extends StatefulWidget {
  final bool allowAutoRoute; // show auto-route control
  final String? employeeId; // when set, show only this employee's route
  const RoutesPage({super.key, this.allowAutoRoute = true, this.employeeId});
  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final _mapController = MapController();

  // Data
  List<VmLocation> _locs = [];
  final List<int> _route = [];         // index order of selected markers
  final Set<int> _selected = {};       // quick membership check

  // UI/async state
  bool _loading = true;
  String? _error;

  // Road-snap polyline cache for ad-hoc selection
  List<LatLng> _roadPath = [];
  bool _routingBusy = false;

  // Auto (employee) routes
  List<EmployeeRoute> _employeeRoutes = [];

  // Hover state for whole-line interaction
  String? _hoveredEmployeeId;
  String? _hoverLabel;
  Offset? _hoverPosPx;      // map-local pixel position
  Color? _hoverColor;
  // Debug: show persisted routes load status and host (for testing)
  String? _persistedRoutesLoadedFrom;

  static const LatLng _homeBase = LatLng(42.9909, -71.4637); // depot
  static const LatLng _bostonCenter = LatLng(42.3601, -71.0589);

  @override
  void initState() {
    super.initState();
    _load();
    // Listen for manager-generated routes so employee views update.
    EmployeeRoutesRepository.lastGenerated.addListener(_onRoutesChanged);
    // Load persisted routes and start polling in background.
    _initPersistedRoutes();
  }

  Future<void> _initPersistedRoutes() async {
    await EmployeeRoutesRepository.loadPersistedRoutes();
    EmployeeRoutesRepository.startAutoRefresh();
    // Surface debugging info about which host served persisted routes
    setState(() {
      _persistedRoutesLoadedFrom = EmployeeRoutesRepository.lastLoadedHost;
    });
    final initial = EmployeeRoutesRepository.lastGenerated.value;
    if (initial != null && initial.isNotEmpty) {
      setState(() {
        _employeeRoutes = List<EmployeeRoute>.from(initial);
        if (widget.employeeId != null) {
          final needle = widget.employeeId!.toString().toLowerCase();
          final match = _employeeRoutes.where((r) => r.employeeId.toString().toLowerCase() == needle).toList();
          if (match.isNotEmpty) {
            _locs = List<VmLocation>.from(match.first.stops);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    EmployeeRoutesRepository.lastGenerated.removeListener(_onRoutesChanged);
    super.dispose();
  }

  void _onRoutesChanged() {
    final val = EmployeeRoutesRepository.lastGenerated.value;
    if (val == null) return;
    setState(() {
      _employeeRoutes = List<EmployeeRoute>.from(val);
      // When routes change and this is an employee view, update the shown locations
      if (widget.employeeId != null) {
        final needle = widget.employeeId!.toString().toLowerCase();
        final match = _employeeRoutes.where((r) => r.employeeId.toString().toLowerCase() == needle).toList();
        if (match.isNotEmpty) {
          _locs = List<VmLocation>.from(match.first.stops);
          // Fit the map to the employee's stops
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitTo(_locs.map((e) => e.ll).toList()));
        } else {
          _locs = [];
        }
      }
    });
  }

  // Public API: allow external callers to request autoroute generation.
  // This is used by the parent layout when the Routes page is shown.
  void generateAutoRoutes() {
    // Fire-and-forget; will update internal state when complete.
    _autoGenerateRoutes();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _employeeRoutes = [];
      _roadPath = [];
      _route.clear();
      _selected.clear();
      _hoveredEmployeeId = null;
      _hoverLabel = null;
      _hoverPosPx = null;
      _hoverColor = null;
    });
    try {
      final locs = await LocationsRepository.load();

      // If this is an employee view, prefer any in-memory assigned route so
      // manager generation in the same process is immediately visible. Start
      // a background persisted load so other clients will pick up manager
      // published routes, but don't await it here (avoid blocking UI).
      if (widget.employeeId != null) {
        final assignedInMemory = EmployeeRoutesRepository.lastGenerated.value;
        if (assignedInMemory != null) {
          final needle = widget.employeeId!.toString().toLowerCase();
          final match = assignedInMemory.where((r) => r.employeeId.toString().toLowerCase() == needle).toList();
          if (match.isNotEmpty) {
            setState(() {
              _locs = List<VmLocation>.from(match.first.stops);
              _loading = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) => _fitTo(_locs.map((e) => e.ll).toList()));
            // Fire-and-forget: attempt to load persisted routes so other clients
            // will also pick them up; do not await here to avoid delaying UI.
            EmployeeRoutesRepository.loadPersistedRoutes();
            return;
          }
        }
        // No in-memory route: kick off persisted load in background and show message
        EmployeeRoutesRepository.loadPersistedRoutes();
        setState(() {
          _locs = [];
          _loading = false;
        });
        return;
      }

      setState(() {
        _locs = locs;
        _loading = false;
      });
      // Fit after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitTo(locs.map((e) => e.ll).toList()));
    } catch (e, st) {
      debugPrint('[RoutesPage] load error: $e\n$st');
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _toggleMarker(int i) {
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
        _route.remove(i);
      } else {
        _selected.add(i);
        _route.add(i);
      }
      _employeeRoutes = []; // clear auto routes when manually selecting
      _hoveredEmployeeId = null;
      _hoverLabel = null;
      _hoverPosPx = null;
      _hoverColor = null;
    });
    _fitTo(_selected.isEmpty ? _locs.map((e) => e.ll).toList() : _currentPoints());
    _updateRoadSnap();
  }

  void _clearRoute() {
    setState(() {
      _selected.clear();
      _route.clear();
      _employeeRoutes = [];
      _roadPath = [];
      _hoveredEmployeeId = null;
      _hoverLabel = null;
      _hoverPosPx = null;
      _hoverColor = null;
    });
  }

  List<LatLng> _currentPoints() => _route.map((i) => _locs[i].ll).toList();

  void _fitTo(List<LatLng> points) {
    if (points.isEmpty) {
      _mapController.move(_bostonCenter, 12);
      return;
    }
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  Future<void> _updateRoadSnap() async {
    final pts = _currentPoints();
    if (pts.length < 2) {
      setState(() => _roadPath = []);
      return;
    }
    setState(() => _routingBusy = true);
    try {
      final rs = await EmployeeRoutesRepository.router.routeSnapped(pts);
      setState(() => _roadPath = rs);
    } catch (e) {
      debugPrint('[RoutesPage] route snap failed; using straight lines: $e');
      setState(() => _roadPath = pts);
    } finally {
      setState(() => _routingBusy = false);
    }
  }

  Future<void> _autoGenerateRoutes() async {
    setState(() {
      _route.clear();
      _selected.clear();
      _roadPath = [];
      _routingBusy = true;
      _employeeRoutes = [];
      _hoveredEmployeeId = null;
      _hoverLabel = null;
      _hoverPosPx = null;
      _hoverColor = null;
    });

    try {
      // Load employees from the repository instead of hard-coding
      final employees = await EmployeesRepository.loadEmployees();

      // If this is an employee view and an assigned route exists, prefer that
      // (in-memory first so manager generation in same process is immediate).
      if (widget.employeeId != null) {
        final assignedInMemory = EmployeeRoutesRepository.lastGenerated.value;
        if (assignedInMemory != null) {
          final needle = widget.employeeId!.toString().toLowerCase();
          final match = assignedInMemory.where((r) => r.employeeId.toString().toLowerCase() == needle).toList();
          if (match.isNotEmpty) {
            setState(() {
              _locs = List<VmLocation>.from(match.first.stops);
              _loading = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) => _fitTo(_locs.map((e) => e.ll).toList()));
            // Kick off background load for persisted routes (don't await)
            EmployeeRoutesRepository.loadPersistedRoutes();
            return;
          }
        }
        // No assigned route in memory yet: kick off background load and continue
        EmployeeRoutesRepository.loadPersistedRoutes();
      }

      if (employees.isEmpty) {
        setState(() => _employeeRoutes = []);
        return;
      }

      final routes = await EmployeeRoutesRepository.generateOptimized(
        homeBase: _homeBase,
        stops: _locs,
        employees: employees,
      );
      setState(() => _employeeRoutes = routes);

      // Fit to all employee polylines + depot
      final allPts = <LatLng>[_homeBase, ...routes.expand((r) => r.geometry)];
      _fitTo(allPts);
    } catch (e, st) {
      debugPrint('[RoutesPage] auto-generate failed: $e\n$st');
      setState(() => _error = 'Auto route error: $e');
    } finally {
      setState(() => _routingBusy = false);
    }
  }

  Future<void> _openRouteInMaps() async {
    // Use current _locs as the stops (employee's route when in employee view)
    if (_locs.isEmpty) return;
    // Build a Google Maps directions URL with waypoints
    final origin = '${_locs.first.ll.latitude},${_locs.first.ll.longitude}';
    final destination = '${_locs.last.ll.latitude},${_locs.last.ll.longitude}';
    final waypoints = _locs.length > 2
        ? _locs.sublist(1, _locs.length - 1).map((s) => '${s.ll.latitude},${s.ll.longitude}').join('|')
        : '';
    final params = StringBuffer('api=1&origin=$origin&destination=$destination');
    if (waypoints.isNotEmpty) params.write('&waypoints=$waypoints');
    final url = Uri.parse('https://www.google.com/maps/dir/?${params.toString()}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // ignore: avoid_print
        print('[RoutesPage] Failed to launch $url');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[RoutesPage] launch exception: $e');
    }
  }

  // ---------------- Whole-line hover detection (no FlutterMapState) ---------

  void _handleHover(PointerHoverEvent e) {
    if (_employeeRoutes.isEmpty) return;

    // Use the controller's camera to project lat/lng to screen points.
  final camera = _mapController.camera;

    final p = e.localPosition; // inside the map widget
    const double thresholdPx = 10.0;

    String? bestId;
    String? bestLabel;
    Color? bestColor;
    double bestDist = thresholdPx;

    // Check distance to each polyline segment
    for (final r in _employeeRoutes) {
      final g = r.geometry;
      if (g.length < 2) continue;

      for (int i = 0; i < g.length - 1; i++) {
        final aPt = camera.latLngToScreenPoint(g[i]);
        final bPt = camera.latLngToScreenPoint(g[i + 1]);

        final a = Offset(aPt.x.toDouble(), aPt.y.toDouble());
        final b = Offset(bPt.x.toDouble(), bPt.y.toDouble());

        final d = _distancePointToSegment(p, a, b);
        if (d < bestDist) {
          bestDist = d;
          bestId = r.employeeId;
          bestLabel = '${r.employeeName} (${r.employeeId})';
          bestColor = r.color;
        }
      }
    }

    if (bestId != null) {
      setState(() {
        _hoveredEmployeeId = bestId;
        _hoverLabel = bestLabel;
        _hoverPosPx = p + const Offset(14, 14); // nudge label off cursor
        _hoverColor = bestColor;
      });
    } else if (_hoveredEmployeeId != null) {
      setState(() {
        _hoveredEmployeeId = null;
        _hoverLabel = null;
        _hoverPosPx = null;
        _hoverColor = null;
      });
    }
  }

  static double _distancePointToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (ab2 == 0) return (p - a).distance; // a==b
    double t = (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      String message = _error!;
      if (_error == 'No employees available from repository.') {
        message = 'No employees in the system. Please add employees.';
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 8),
            Text('Failed to load', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(message, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      );
    }

    // For employee view, if no route assigned (or no stops), show message
    if (widget.employeeId != null && _locs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route, size: 36),
            const SizedBox(height: 8),
            Text('No route assigned yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            if (_persistedRoutesLoadedFrom != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Checked persisted routes from $_persistedRoutesLoadedFrom', style: Theme.of(context).textTheme.bodySmall),
              ),
            const Text('Please contact your manager for route assignment.'),
          ],
        ),
      );
    }

    // Small, uncluttered markers (no always-visible labels)
    final markers = <Marker>[
      Marker(
        point: _homeBase,
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: const _HomeBaseMarker(),
      ),
      for (int i = 0; i < _locs.length; i++)
        Marker(
          point: _locs[i].ll,
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _toggleMarker(i),
            child: _MachineMarker(selected: _selected.contains(i)),
          ),
        ),
    ];

    final showManualPath = _employeeRoutes.isEmpty && _roadPath.length >= 2;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _bostonCenter,
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.vending',
            ),

            // Marker clustering to avoid pixel overlap
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                markers: markers,
                maxClusterRadius: 50,
                size: const Size(40, 40),
                // fitBoundsOptions not available in 1.3.x
                zoomToBoundsOnClick: true,
                centerMarkerOnClick: true,
                spiderfyCircleRadius: 35,
                spiderfySpiralDistanceMultiplier: 2,
                showPolygon: false,
                builder: (context, clusterMarkers) =>
                    _ClusterBubble(count: clusterMarkers.length),
              ),
            ),

            if (showManualPath)
              PolylineLayer(
                polylines: [
                  Polyline(points: _roadPath, strokeWidth: 5, color: cs.primary),
                ],
              ),

            if (_employeeRoutes.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (final r in _employeeRoutes)
                    if (widget.employeeId == null || widget.employeeId == r.employeeId)
                      Polyline(
                        points: r.geometry,
                        strokeWidth: r.employeeId == _hoveredEmployeeId ? 7 : 5,
                        color: (r.employeeId == _hoveredEmployeeId
                                ? r.color
                                : r.color.withOpacity(0.80)),
                        borderColor: r.employeeId == _hoveredEmployeeId
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.25),
                        borderStrokeWidth: r.employeeId == _hoveredEmployeeId ? 2.5 : 1.5,
                      ),
                ],
              ),
          ],

          // Non-rotated overlay that receives pointer events without blocking the map
          nonRotatedChildren: [
            if (_employeeRoutes.isNotEmpty && widget.allowAutoRoute)
              MouseRegion(
                onHover: _handleHover,
                onExit: (_) {
                  if (_hoveredEmployeeId != null) {
                    setState(() {
                      _hoveredEmployeeId = null;
                      _hoverLabel = null;
                      _hoverPosPx = null;
                      _hoverColor = null;
                    });
                  }
                },
                child: const SizedBox.expand(),
              ),
          ],
        ),

        // Floating hover label (placed via pixel coords)
        if (_hoverLabel != null && _hoverPosPx != null)
          Positioned(
            left: _hoverPosPx!.dx,
            top: _hoverPosPx!.dy,
            child: _HoverBadge(text: _hoverLabel!, color: _hoverColor ?? cs.primary),
          ),

        // Top-left controls
        Positioned(
          left: 12,
          top: 12,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Control(
                icon: Icons.center_focus_strong,
                label: 'Fit',
                onTap: () => _fitTo(_locs.map((e) => e.ll).toList()),
              ),
              // Employee view: only show Fit and Open in Maps
              if (widget.employeeId != null) ...[
                _Control(icon: Icons.map, label: 'Open in Maps', onTap: _openRouteInMaps),
              ] else ...[
                _Control(icon: Icons.clear, label: 'Clear route', onTap: _clearRoute),
                if (widget.allowAutoRoute)
                  _Control(
                    icon: Icons.route,
                    label: _routingBusy ? 'Routing…' : 'Auto routes',
                    onTap: _routingBusy ? null : _autoGenerateRoutes,
                  ),
                _Hint(text: 'Hover a route to see the employee'),
              ],
            ],
          ),
        ),

        // Top-right count badge
        Positioned(
          right: 12,
          top: 12,
          child: widget.employeeId != null
              ? _CountBadge(shown: _locs.length, total: _locs.length)
              : _CountBadge(shown: _locs.length, total: _locs.length),
        ),

        // Bottom chip list for selected route (manual mode)
        if (_route.isNotEmpty && _employeeRoutes.isEmpty)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int step = 0; step < _route.length; step++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('${step + 1}. ${_locs[_route[step]].name}'),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => _toggleMarker(_route[step]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---- Small widgets ----

class _ClusterBubble extends StatelessWidget {
  final int count;
  const _ClusterBubble({required this.count});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text('$count',
          style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
    );
  }
}

class _HomeBaseMarker extends StatelessWidget {
  const _HomeBaseMarker();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(Icons.home_filled, color: cs.error, size: 28);
  }
}

class _MachineMarker extends StatelessWidget {
  final bool selected;
  const _MachineMarker({required this.selected});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(
      selected ? Icons.location_on : Icons.location_on_outlined,
      color: selected ? cs.error : cs.primary,
      size: 24,
    );
  }
}

class _Control extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Control({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int shown;
  final int total;
  const _CountBadge({required this.shown, required this.total});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text('Showing $shown / $total',
          style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _HoverBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _HoverBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.7)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
