import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'RoutePlanner.dart';

class MapInterface extends StatelessWidget {
  const MapInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoutePlanner()..loadRoutes(),
      child: Consumer<RoutePlanner>(
        builder: (context, planner, child) {
          if (planner.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Default to Boston center if no locations or use the first location
          final center = planner.locations.isNotEmpty
              ? LatLng(
                  (planner.locations.first['lat'] as num).toDouble(),
                  (planner.locations.first['lng'] as num).toDouble(),
                )
              : const LatLng(42.3550, -71.0656);

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: planner.locations.map((loc) {
                  final lat = (loc['lat'] as num).toDouble();
                  final lng = (loc['lng'] as num).toDouble();
                  return Marker(
                    point: LatLng(lat, lng),
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
