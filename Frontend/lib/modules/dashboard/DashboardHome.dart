import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import 'BusinessMetrics.dart';
import 'widgets/DashboardMetrics.dart';
import 'widgets/MachineStopCard.dart';
import '../../core/styles/AppStyle.dart';

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
    final isManager = session.isManager;

    if (metrics.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.border));
    }

    final machineIdsToDisplay = isManager 
        ? metrics.inventory.keys.toList() 
        : metrics.inventory.keys.where((id) => metrics.userMachineIds.contains(id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'SYSTEM OVERVIEW', subtitle: 'LIVE ENVIRONMENT METRICS'),
          const SizedBox(height: 20),
          DashboardMetrics(
            totalMachines: isManager ? metrics.totalMachines : machineIdsToDisplay.length,
            onlineMachines: isManager ? metrics.onlineMachines : machineIdsToDisplay.length,
            revenueToday: metrics.revenueToday,
            showRevenue: isManager,
          ),
          const SizedBox(height: 48),
          _SectionHeader(
            title: isManager ? 'ALL NETWORK NODES' : 'ASSIGNED ROUTE NODES', 
            subtitle: 'REAL-TIME STATUS & PAYLOAD',
          ),
          const SizedBox(height: 20),
          if (machineIdsToDisplay.isEmpty && !isManager)
            Center(child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Text('NO NODES ASSIGNED', style: AppStyle.label()),
            )),
          ...machineIdsToDisplay.map((mid) {
            final items = metrics.inventory[mid] ?? [];
            return MachineStopCard(
              machineId: mid,
              machineName: 'UNIT $mid',
              items: items,
              isOnline: true,
              onUpdateQuantity: (sku, newQty) {
                metrics.updateItemQuantity(mid, sku, newQty);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppStyle.label(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.dataPrimary, letterSpacing: 1.0)),
        Text(subtitle, style: AppStyle.label(fontSize: 10, color: AppColors.dataSecondary, letterSpacing: 0.5)),
      ],
    );
  }
}
