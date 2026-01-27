import 'package:flutter/material.dart';
import '../../../core/styles/AppStyle.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: AppStyle.surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.dataSecondary),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: AppStyle.label(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppStyle.metric(fontSize: 24, fontWeight: FontWeight.bold, color: color ?? AppColors.dataPrimary),
          ),
        ],
      ),
    );
  }
}
