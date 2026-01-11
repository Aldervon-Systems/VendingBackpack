import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (session.isManager)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Employee View'),
                subtitle: const Text('Hide manager-only views for this session.'),
                value: session.isInEmployeeView,
                onChanged: (enabled) => session.setEmployeeView(enabled),
              ),
            if (!session.isManager)
              const Text('No settings available for this account.'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
