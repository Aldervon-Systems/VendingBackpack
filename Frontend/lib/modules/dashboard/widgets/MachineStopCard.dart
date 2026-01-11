import 'package:flutter/material.dart';

class MachineStopCard extends StatelessWidget {
  final String machineId;
  final String machineName;
  final bool isOnline;
  final int itemCount;

  const MachineStopCard({
    super.key,
    required this.machineId,
    required this.machineName,
    this.isOnline = true,
    this.itemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.devices, color: isOnline ? Colors.green : Colors.grey, size: 32),
        title: Text(machineName),
        subtitle: Text('ID: $machineId | Items: $itemCount'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
