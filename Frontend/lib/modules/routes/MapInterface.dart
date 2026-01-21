import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import 'RoutePlanner.dart';

class MapInterface extends StatelessWidget {
  const MapInterface({super.key});

  @override
  void _showAssignmentModal(BuildContext context, RoutePlanner planner, String machineId, String machineName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Assign $machineName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Select Employee:'),
              const SizedBox(height: 8),
              if (planner.employees.isEmpty)
                const Text('No employees found')
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: planner.employees.length,
                    itemBuilder: (ctx, index) {
                      final emp = planner.employees[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(emp['name'][0])),
                        title: Text(emp['name']),
                        onTap: () {
                          planner.assignMachineToEmployee(machineId, emp['id']);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Assigned to ${emp['name']}')),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionManager>(context);
    final isManager = session.isManager && session.effectiveRole == 'manager';
    final restrictedId = isManager ? null : session.currentUser?.id.toString();

    return ChangeNotifierProvider(
      key: ValueKey(restrictedId), // Re-create planner if user/restriction changes
      create: (_) => RoutePlanner(restrictedEmployeeId: restrictedId)..loadRoutes(),
      child: Consumer<RoutePlanner>(
        builder: (context, planner, child) {
          if (planner.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final center = planner.locations.isNotEmpty
              ? LatLng(
                  (planner.locations.first['lat'] as num).toDouble(),
                  (planner.locations.first['lng'] as num).toDouble(),
                )
              : const LatLng(42.3550, -71.0656);

          // If restricted, only show locations in the active route
          final visibleLocations = isManager 
             ? planner.locations 
             : (planner.locations as List).where((loc) {
                 return planner.activeRouteStops.any((stop) => stop['id'] == loc['id']);
               }).toList();

          return Column(
            children: [
              // Employee Selector for overlay
              if (isManager)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Show Route: '),
                    DropdownButton<String>(
                      value: planner.activeEmployeeId,
                      hint: const Text('Select Employee'),
                      onChanged: (val) => planner.selectEmployee(val),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        const DropdownMenuItem(value: 'all', child: Text('All Employees')),
                        ...planner.employees.map((e) => DropdownMenuItem(
                          value: e['id'].toString(),
                          child: Text(e['name']),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 13.0,
                     ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        PolylineLayer(
                          polylines: [
                            for (final route in planner.polylines)
                              Polyline(
                                points: (route['points'] as List<List<double>>).map((p) => LatLng(p[0], p[1])).toList(),
                                strokeWidth: 4.0,
                                color: Color(route['color'] as int),
                              ),
                          ],
                        ),
                        MarkerLayer(
                          markers: visibleLocations.map((loc) {
                            final lat = (loc['lat'] as num).toDouble();
                            final lng = (loc['lng'] as num).toDouble();
                            return Marker(
                              point: LatLng(lat, lng),
                              width: 80,
                              height: 80,
                              child: isManager ? GestureDetector(
                                onTap: () => _showAssignmentModal(context, planner, loc['id'].toString(), loc['name']),
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ) : const Icon(Icons.location_on, color: Colors.red, size: 40),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    if (isManager && planner.activeEmployeeId != null && planner.activeEmployeeId != 'all')
                       _buildRouteEditorPanel(context, planner),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteEditorPanel(BuildContext context, RoutePlanner planner) {
    // We need a local state for editing, but RoutePlanner state is what we have.
    // Ideally we shouldn't mutate RoutePlanner state directly until save, BUT 
    // for MVP simplicity, we can edit a local list copy or just use the planner state if we add "setLocalStops" method.
    // I'll make the panel Stateful or just use a StatefulBuilder.
    // Let's use a StatefulBuilder to manage the editing list locally before saving.
    
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              // Initialize editable list from planner if not set (would need persistent state if we want to keep edits across rebuilds, 
              // but here rebuilds happen when planner changes so it's tricky.
              // Actually, simplest is to let the user edit the active stops in place or create a UI that maps to the currents stops.
              // BUT, user wants to *customize* them.
              
              // Let's assume the user edits `planner.activeRouteStops` directly? No, that triggers map updates immediately if we notify listeners.
              // Maybe that's desired? "Realtime preview"? 
              // User said "Customize... display each stop... allow them to be customized".
              // If I update planner state, the line redraws. That's cool.
              // But `updateRouteStops` (PUT) is the final save.
              // So I should have `planner.setLocalStops(List stops)` which updates visual but not backend? 
              // I didn't add that. I only added `updateRouteStops` which calls backend.
              
              // Solution: Manage a local list in this StatefulBuilder, and Save calls `updateRouteStops`.
              // Challenge: Syncing initial state. StatefulBuilder doesn't auto-reset when parent rebuilds unless key changes.
              // We'll trust the planner's activeRouteStops are the source. We copy them to a local list on init? 
              // No, `StatefulBuilder` is ephemeral.
              // Use a separate `_RouteEditor` widget class would be cleaner.
              
              return _RouteEditor(planner: planner, scrollController: scrollController);
            },
          ),
        );
      },
    );
  }
}

class _RouteEditor extends StatefulWidget {
  final RoutePlanner planner;
  final ScrollController scrollController;

  const _RouteEditor({required this.planner, required this.scrollController});

  @override
  State<_RouteEditor> createState() => _RouteEditorState();
}

class _RouteEditorState extends State<_RouteEditor> {
  late List<dynamic> _stops;

  @override
  void initState() {
    super.initState();
    _stops = List.from(widget.planner.activeRouteStops);
  }

  @override
  void didUpdateWidget(_RouteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planner.activeRouteStops != widget.planner.activeRouteStops) {
       // Only reset if the planner's source of truth changed externally (e.g. reload)
       // Checking equality is hard for lists, assuming reference change or length change
       if (_stops.length != widget.planner.activeRouteStops.length) {
          _stops = List.from(widget.planner.activeRouteStops);
       }
    }
  }

  void _save() {
    final stopIds = _stops.map((s) => s['id'] as String).toList();
    if (widget.planner.activeEmployeeId != null) {
      widget.planner.updateRouteStops(widget.planner.activeEmployeeId!, stopIds);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLocations = widget.planner.locations;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: _stops.length + 1, // +1 for Add button
            itemBuilder: (context, index) {
              if (index == _stops.length) {
                return TextButton.icon(
                  onPressed: () {
                    setState(() {
                      // Add placeholder or first available location
                      if (allLocations.isNotEmpty) {
                        _stops.add(allLocations.first);
                      }
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Stop'),
                );
              }

              final stop = _stops[index];
              final stopId = stop['id'];
              final isValid = allLocations.any((l) => l['id'] == stopId);
              
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: DropdownButton<String>(
                  isExpanded: true,
                  value: isValid ? stopId : null,
                  hint: isValid ? null : Text('Unknown Location ($stopId)'),
                  items: allLocations.map((loc) {
                    return DropdownMenuItem<String>(
                      value: loc['id'],
                      child: Text(loc['name']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      final newLoc = allLocations.firstWhere((l) => l['id'] == val);
                      _stops[index] = newLoc;
                    });
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _stops.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
