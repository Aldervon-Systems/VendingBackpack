import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import 'BusinessMetrics.dart';
import 'widgets/DashboardMetrics.dart';
import 'widgets/MachineStopCard.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final metrics = context.read<BusinessMetrics>();
      metrics.loadData();
      final session = context.read<SessionManager>();
      if (!session.isManager && session.currentUser != null) {
        metrics.fetchUserRoute(session.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.watch<BusinessMetrics>();
    final session = context.watch<SessionManager>();
    final user = session.currentUser;
    final isManager = session.isManager;

    if (metrics.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter machine IDs for employees
    final machineIdsToDisplay = isManager 
        ? metrics.inventory.keys.toList() 
        : metrics.inventory.keys.where((id) => metrics.userMachineIds.contains(id)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null)
          Text('Welcome, ${user.name}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        DashboardMetrics(
          totalMachines: isManager ? metrics.totalMachines : machineIdsToDisplay.length,
          onlineMachines: isManager ? metrics.onlineMachines : machineIdsToDisplay.length,
          revenueToday: metrics.revenueToday,
          showRevenue: isManager,
        ),
        const SizedBox(height: 16),
        Text(
          isManager ? 'All Machines Status' : 'My Route Machines', 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        if (machineIdsToDisplay.isEmpty && !isManager)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No machines assigned to your route.'),
          )),
        ...machineIdsToDisplay.map((mid) {
          final items = metrics.inventory[mid] ?? [];
          return MachineStopCard(
            machineId: mid,
            machineName: 'Machine $mid',
            items: items,
            isOnline: true,
            onUpdateQuantity: (sku, newQty) {
              metrics.updateItemQuantity(mid, sku, newQty);
            },
          );
        }),
      ],
    );
  }
}
