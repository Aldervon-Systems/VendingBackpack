import 'package:flutter/material.dart';
import 'MetricCard.dart';

class DashboardMetrics extends StatelessWidget {
  final int totalMachines;
  final int onlineMachines;
  final double revenueToday;
  final bool showRevenue;

  const DashboardMetrics({
    super.key,
    required this.totalMachines,
    required this.onlineMachines,
    required this.revenueToday,
    this.showRevenue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        MetricCard(
          label: 'Total Machines',
          value: totalMachines.toString(),
          icon: Icons.devices,
        ),
        MetricCard(
          label: 'Online',
          value: onlineMachines.toString(),
          icon: Icons.wifi,
          color: Colors.green,
        ),
        if (showRevenue)
        MetricCard(
          label: 'Revenue Today',
          value: '\$${revenueToday.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.blue,
        ),
      ],
    );
  }
}
