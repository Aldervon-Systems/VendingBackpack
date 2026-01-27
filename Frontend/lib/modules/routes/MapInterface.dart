import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import 'RoutePlanner.dart';
import '../../core/styles/AppStyle.dart';

class MapInterface extends StatelessWidget {
  const MapInterface({super.key});

  void _showAssignmentModal(BuildContext context, RoutePlanner planner, String machineId, String machineName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ASSIGNMENT / NODE $machineId', style: AppStyle.label(fontWeight: FontWeight.w800, color: AppColors.dataPrimary, letterSpacing: 1.0)),
              Text('SELECT OPERATIVE FOR $machineName', style: AppStyle.label(fontSize: 10)),
              const SizedBox(height: 24),
              if (planner.employees.isEmpty)
                Text('NO OPERATIVES DETECTED', style: AppStyle.label())
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: planner.employees.length,
                    itemBuilder: (ctx, index) {
                      final emp = planner.employees[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.foundation,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          title: Text(emp['name'], style: AppStyle.label(fontWeight: FontWeight.bold, color: AppColors.dataPrimary)),
                          trailing: const Icon(Icons.chevron_right, size: 16),
                          onTap: () {
                            planner.assignMachineToEmployee(machineId, emp['id']);
                            Navigator.pop(ctx);
                          },
                        ),
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
      key: ValueKey(restrictedId),
      create: (_) => RoutePlanner(restrictedEmployeeId: restrictedId)..loadRoutes(),
      child: Consumer<RoutePlanner>(
        builder: (context, planner, child) {
          if (planner.isLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.border));
          }
          
          final center = planner.locations.isNotEmpty
              ? LatLng(
                  (planner.locations.first['lat'] as num).toDouble(),
                  (planner.locations.first['lng'] as num).toDouble(),
                )
              : const LatLng(42.3550, -71.0656);

          final visibleLocations = isManager 
             ? planner.locations 
             : (planner.locations as List).where((loc) {
                 return planner.activeRouteStops.any((stop) => stop['id'] == loc['id']);
               }).toList();

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', // Using a lighter, minimalist map
                    userAgentPackageName: 'com.vendingbackpack.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      for (final route in planner.polylines)
                        Polyline(
                          points: (route['points'] as List<List<double>>).map((p) => LatLng(p[0], p[1])).toList(),
                          strokeWidth: 2.0,
                          color: AppColors.actionAccent.withOpacity(0.6),
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: visibleLocations.map((loc) {
                      final lat = (loc['lat'] as num).toDouble();
                      final lng = (loc['lng'] as num).toDouble();
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 40, height: 40,
                        child: GestureDetector(
                          onTap: isManager ? () => _showAssignmentModal(context, planner, loc['id'].toString(), loc['name']) : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.actionAccent, width: 2),
                              boxShadow: [BoxShadow(color: AppColors.actionAccent.withOpacity(0.2), blurRadius: 8)],
                            ),
                            child: const Icon(Icons.sensors, size: 16, color: AppColors.actionAccent),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              if (isManager)
                Positioned(
                  top: 24, left: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: AppStyle.surfaceCard,
                    child: Row(
                      children: [
                        Text('FILTER // ', style: AppStyle.label(fontSize: 10, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: planner.activeEmployeeId,
                          underline: const SizedBox(),
                          style: AppStyle.label(fontWeight: FontWeight.bold, color: AppColors.dataPrimary),
                          onChanged: (val) => planner.selectEmployee(val),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('NONE')),
                            const DropdownMenuItem(value: 'all', child: Text('ALL NODES')),
                            ...planner.employees.map((e) => DropdownMenuItem(
                              value: e['id'].toString(),
                              child: Text(e['name'].toUpperCase()),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (isManager && planner.activeEmployeeId != null && planner.activeEmployeeId != 'all')
                 _RouteEditorPanel(planner: planner),
            ],
          );
        },
      ),
    );
  }
}

class _RouteEditorPanel extends StatelessWidget {
  final RoutePlanner planner;
  const _RouteEditorPanel({required this.planner});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: _RouteEditor(planner: planner, scrollController: scrollController),
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

  void _save() {
    final stopIds = _stops.map((s) => s['id'] as String).toList();
    if (widget.planner.activeEmployeeId != null) {
      widget.planner.updateRouteStops(widget.planner.activeEmployeeId!, stopIds);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text('ROUTE RECONFIGURED', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLocations = widget.planner.locations;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ROUTE_SEQUENCE // EDIT', style: AppStyle.label(fontWeight: FontWeight.w800, color: AppColors.dataPrimary, letterSpacing: 1.0)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionAccent, elevation: 0),
                onPressed: _save, 
                child: Text('SAVE', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: _stops.length + 1,
            itemBuilder: (context, index) {
              if (index == _stops.length) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () {
                      if (allLocations.isNotEmpty) setState(() => _stops.add(allLocations.first));
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('APPEND NODE', style: AppStyle.label(fontWeight: FontWeight.bold)),
                  ),
                );
              }

              final stop = _stops[index];
              final stopId = stop['id'];
              final isValid = allLocations.any((l) => l['id'] == stopId);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                decoration: BoxDecoration(color: AppColors.foundation, borderRadius: BorderRadius.circular(6)),
                child: ListTile(
                  leading: Text('#${index + 1}', style: AppStyle.metric(fontSize: 12, color: AppColors.dataSecondary)),
                  title: DropdownButton<String>(
                    isExpanded: true,
                    value: isValid ? stopId : null,
                    underline: const SizedBox(),
                    items: allLocations.map((loc) {
                      return DropdownMenuItem<String>(
                        value: loc['id'],
                        child: Text(loc['name'].toUpperCase(), style: AppStyle.label(fontSize: 12, color: AppColors.dataPrimary)),
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
                    icon: const Icon(Icons.close, size: 16, color: AppColors.warning),
                    onPressed: () => setState(() => _stops.removeAt(index)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
