import 'package:flutter/material.dart';
import 'overlay_blur_window.dart';

class SettingsOverlay extends StatelessWidget {
  final VoidCallback? onClose;
  const SettingsOverlay({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return OverlayBlurWindow(
      onTapOutside: onClose,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).round()),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Settings go here.'),
            // Add more settings widgets as needed
          ],
        ),
      ),
    );
  }
}
