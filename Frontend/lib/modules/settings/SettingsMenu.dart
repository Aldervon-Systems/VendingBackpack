import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import '../auth/AdminVerificationDialog.dart';
import '../auth/OrganizationOnboardingScreen.dart';
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.foundation,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.currentUser?.name.toUpperCase() ?? 'NO SESSION', style: AppStyle.label(fontWeight: FontWeight.bold, color: AppColors.dataPrimary)),
              const SizedBox(height: 4),
              Text(session.currentUser?.email ?? 'Not signed in', style: AppStyle.label(fontSize: 10)),
              const SizedBox(height: 4),
              Text('ROLE: ${session.effectiveRole.toUpperCase()}', style: AppStyle.label(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (session.isManager) ...[
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
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: session.isAdminVerified ? Colors.green.withOpacity(0.1) : AppColors.foundation,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: session.isAdminVerified ? Colors.green : AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ORG ADMIN ACCESS', style: AppStyle.label(fontWeight: FontWeight.bold, color: session.isAdminVerified ? Colors.green : AppColors.dataPrimary)),
                      Text(session.isAdminVerified ? 'Verified: Administrative commands unlocked' : 'Requires Dual-Key Challenge', style: AppStyle.label(fontSize: 10)),
                    ],
                  ),
                ),
                if (!session.isAdminVerified)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.actionAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AdminVerificationDialog(organizationId: session.currentUser?.organizationId ?? ''),
                      );
                    },
                    child: Text('VERIFY', style: AppStyle.label(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else
                  const Icon(Icons.verified_user, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrganizationOnboardingScreen()),
                );
              },
              child: Text(
                'PROVISION NEW ORGANIZATION',
                style: AppStyle.label(color: AppColors.actionAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ]
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
