// Organism: DashboardMetrics
// Single Functionality: Display dashboard statistics metrics

import 'package:flutter/material.dart';
import '../molecules/metric_card.dart';
import '../../api/dashboard_store.dart';
import '../../api/local_data.dart';
import 'weekly_bar_chart.dart';

class DashboardMetrics extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const DashboardMetrics({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final dashboard = snapshot.dashboard;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricCard(
                label: 'Total Machines',
                value: dashboard.machinesTotal.toString(),
                icon: Icons.devices,
              ),
              MetricCard(
                label: 'Online',
                value: dashboard.machinesOnline.toString(),
                icon: Icons.wifi,
                color: Colors.green,
              ),
              MetricCard(
                label: 'Revenue Today',
                value: '\$${dashboard.revenueToday.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Make the chart larger: take roughly half of the upper area depending on
        // screen width. On narrow screens this will naturally compress.
        LayoutBuilder(builder: (context, constraints) {
          final screenW = MediaQuery.of(context).size.width;
          final chartW = (screenW * 0.48).clamp(240.0, 680.0);
          final chartH = (MediaQuery.of(context).size.height * 0.28).clamp(160.0, 320.0);
          return SizedBox(
            width: chartW,
            child: FutureBuilder<List<dynamic>>(
              future: LocalData.weeklyStats(),
              builder: (context, snap) {
                if (!snap.hasData) return SizedBox(height: chartH, child: Center(child: CircularProgressIndicator()));
                final list = (snap.data ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
                return WeeklyBarChart(data: list, height: chartH);
              },
            ),
          );
        }),
      ],
    );
  }
}
