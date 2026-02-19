import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/styles/AppStyle.dart';
import './SessionManager.dart';

class AdminVerificationDialog extends StatefulWidget {
  final String organizationId;
  const AdminVerificationDialog({super.key, required this.organizationId});

  @override
  State<AdminVerificationDialog> createState() => _AdminVerificationDialogState();
}

class _AdminVerificationDialogState extends State<AdminVerificationDialog> {
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _verify() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await context.read<SessionManager>().verifyAdmin(
        organizationId: widget.organizationId,
        adminPassword: _passwordController.text,
        totpCode: _totpController.text,
      );

      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'Verification failed');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.foundation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DUAL-KEY CHALLENGE', style: AppStyle.label(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.actionAccent)),
            const SizedBox(height: 8),
            Text('Provide secondary credentials to access administrative backend.', style: AppStyle.label(color: AppColors.dataSecondary)),
            const SizedBox(height: 24),
            _LabTextField(
              controller: _passwordController,
              label: 'ORGANIZATION ADMIN PASSWORD',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _LabTextField(
              controller: _totpController,
              label: '6-DIGIT TOTP CODE',
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!.toUpperCase(), style: AppStyle.label(color: AppColors.warning, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL', style: AppStyle.label()),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionAccent),
                    onPressed: _isLoading ? null : _verify,
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('VERIFY', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _LabTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyle.label(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.foundation,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
