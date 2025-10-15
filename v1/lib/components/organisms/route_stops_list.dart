// Organism: RouteStopsList
// Single Functionality: Display all machine stops in an employee's route

import 'package:flutter/material.dart';
import '../molecules/machine_stop_card.dart';
import '../atoms/app_text.dart';
import '../../api/locations_repository.dart';

class RouteStopsList extends StatelessWidget {
  final List<VmLocation> stops;
  final Function(String machineId, String sku)? onFillItem;
  final Function(String machineId)? onFillAll;

  const RouteStopsList({
    super.key,
    required this.stops,
    this.onFillItem,
    this.onFillAll,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Center(
        child: AppText.body('No stops assigned'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        return MachineStopCard(
          machineId: stop.id,
          machineName: stop.name,
          onFillItem: onFillItem != null 
              ? (sku) => onFillItem!(stop.id, sku) 
              : null,
          onFillAll: onFillAll != null 
              ? () => onFillAll!(stop.id) 
              : null,
        );
      },
    );
  }
}
