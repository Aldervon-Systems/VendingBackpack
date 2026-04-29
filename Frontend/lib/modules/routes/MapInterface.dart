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
                          title: Text(emp.name, style: AppStyle.label(fontWeight: FontWeight.bold, color: AppColors.dataPrimary)),
                          trailing: const Icon(Icons.chevron_right, size: 16),
                          onTap: () {
                            planner.assignMachineToEmployee(machineId, emp.id);
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

    return Consumer<RoutePlanner>(
      builder: (context, planner, child) {
        if (planner.isLoading && planner.locations.isEmpty) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.border));
        }
        
        final center = planner.locations.isNotEmpty
            ? LatLng(
                planner.locations.first.lat ?? 42.3550,
                planner.locations.first.lng ?? -71.0656,
              )
            : const LatLng(42.3550, -71.0656);

        final visibleLocations = isManager
            ? planner.locations
            : planner.locations.where((loc) {
                return planner.activeRouteStops
                    .any((stop) => stop.machineId == loc.id);
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
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', 
                  userAgentPackageName: 'com.vendingbackpack.app',
                ),
                PolylineLayer(
                  polylines: [
                    // Render all routes
                    for (final entry in planner.allPolylines.entries) ...[
                      if (entry.value['points'] != null)
                        Polyline(
                          points: (entry.value['points'] as List).map((p) => LatLng(p[0], p[1])).toList(),
                          strokeWidth: entry.key == planner.activeEmployeeId ? 5.0 : 2.5,
                          color: Color(entry.value['color']).withOpacity(
                            entry.key == planner.activeEmployeeId ? 1.0 : 0.4
                          ),
                        ),
                    ]
                  ],
                ),
                MarkerLayer(
                  markers: visibleLocations.map((loc) {
                    final lat = loc.lat;
                    final lng = loc.lng;
                    if (lat == null || lng == null) return null;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 40, height: 40,
                      child: GestureDetector(
                        onTap: isManager ? () => _showAssignmentModal(context, planner, loc.id, loc.name) : null,
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
                  }).whereType<Marker>().toList(),
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
                            value: e.id,
                            child: Text(e.name.toUpperCase()),
                          )),
                        ],
                      ),
                      const SizedBox(width: 8),
                      if (planner.isLoading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.actionAccent))
                      else
                        IconButton(
                          onPressed: () => planner.autogenerateRoutes(),
                          icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.actionAccent),
                          tooltip: 'AUTO-GENERATE ALL ROUTES',
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
