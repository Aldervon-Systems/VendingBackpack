import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import '../../core/styles/AppStyle.dart';

class SettingsMenu extends StatelessWidget {
  final VoidCallback? onClose;

  const SettingsMenu({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONFIGURATION / SESSION', style: AppStyle.label(fontWeight: FontWeight.w800, color: AppColors.dataPrimary, letterSpacing: 1.0)),
        const SizedBox(height: 24),
        if (session.isManager)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.foundation,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EMPLOYEE SIMULATION', style: AppStyle.label(fontWeight: FontWeight.bold, color: AppColors.dataPrimary)),
                      Text('Restricts view to standard operative nodes', style: AppStyle.label(fontSize: 10)),
                    ],
                  ),
                ),
                Switch(
                  value: session.isInEmployeeView,
                  onChanged: (enabled) => session.setEmployeeView(enabled),
                  activeColor: AppColors.actionAccent,
                ),
              ],
            ),
          )
        else
          Text('NO CONFIGURABLE PARAMETERS FOR THIS SECURITY LEVEL', style: AppStyle.label(fontSize: 10)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dataPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: onClose ?? () => Navigator.of(context).maybePop(),
            child: Text('DISMISS', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
