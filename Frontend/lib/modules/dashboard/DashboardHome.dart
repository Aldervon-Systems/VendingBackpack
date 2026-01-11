import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import 'BusinessMetrics.dart';
import 'widgets/DashboardMetrics.dart';
import 'widgets/MachineStopCard.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = context.watch<BusinessMetrics>();
    final user = context.read<SessionManager>().currentUser;

    if (metrics.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null)
          Text('Welcome, ${user.name}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        DashboardMetrics(
          totalMachines: metrics.totalMachines,
          onlineMachines: metrics.onlineMachines,
          revenueToday: metrics.revenueToday,
        ),
        const SizedBox(height: 16),
        const Text('Machines Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...metrics.inventory.keys.map((mid) {
          final items = metrics.inventory[mid] ?? [];
          return MachineStopCard(
            machineId: mid,
            machineName: 'Machine $mid',
            itemCount: items.length,
            isOnline: true,
          );
        }),
      ],
    );
  }
}
