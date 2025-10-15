// Molecule: MetricCard
// Single Functionality: Display a single dashboard metric with icon and value

import 'package:flutter/material.dart';
import '../atoms/app_text.dart';

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
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.primaryColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: effectiveColor, size: 24),
                const SizedBox(width: 8),
                AppText.caption(label),
              ],
            ),
            const SizedBox(height: 8),
            AppText.title(value),
          ],
        ),
      ),
    );
  }
}
