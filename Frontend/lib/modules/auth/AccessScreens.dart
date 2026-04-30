import 'package:flutter/material.dart';
import 'SessionManager.dart';
import 'OrganizationOnboardingScreen.dart';
import 'package:provider/provider.dart';
import '../../core/styles/AppStyle.dart';
import '../../core/services/SurfaceControl.dart';

class AccessScreens extends StatefulWidget {
  const AccessScreens({super.key, this.initialTarget});

  final SurfaceLaunchTarget? initialTarget;

  @override
  State<AccessScreens> createState() => _AccessScreensState();
}

class _AccessScreensState extends State<AccessScreens> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _orgSearchController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;
  String _selectedRole = 'employee';
  String? _selectedOrgId;
  String? _selectedOrgName;
  List<Map<String, dynamic>> _orgSearchResults = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialTarget == SurfaceLaunchTarget.authRegister) {
      _isLoginMode = false;
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isLoginMode) {
        await context.read<SessionManager>().login(
          _emailController.text,
          _passwordController.text,
          organizationId: _selectedOrgId,
        );
      } else {
        await context.read<SessionManager>().signup(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
          role: _selectedRole,
          organizationId: _selectedOrgId,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        String message = e.toString().replaceFirst('Exception: ', '');
        if (message.contains('User already exists')) {
          _error = 'Account exists';
        } else if (message.contains('Invalid credentials')) {
          _error = 'Invalid credentials';
        } else if (message.contains('Email not authorized')) {
          _error = 'Whitelist rejection';
        } else {
          _error = 'Server error';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchOrgs(String query) async {
    if (query.isEmpty) {
      setState(() => _orgSearchResults = []);
      return;
    }
    try {
      final results = await context.read<SessionManager>().searchOrganizations(query);
      setState(() => _orgSearchResults = results);
    } catch (e) {
      debugPrint('Org search failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foundation,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(40),
            decoration: AppStyle.surfaceCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.dataPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 24),
                Text(
                  _isLoginMode ? 'Sign In' : 'Register',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dataPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Access the VBP Lab Environment',
                  style: AppStyle.label(fontSize: 14),
                ),
                const SizedBox(height: 32),
                if (_selectedOrgId != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.actionAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.actionAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business, size: 16, color: AppColors.actionAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TENANT: ${_selectedOrgName!.toUpperCase()}',
                            style: AppStyle.label(color: AppColors.actionAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, size: 16, color: AppColors.actionAccent),
                          onPressed: () => setState(() {
                            _selectedOrgId = null;
                            _selectedOrgName = null;
                            _orgSearchController.clear();
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  _LabTextField(
                    controller: _orgSearchController,
                    label: 'SELECT ORGANIZATION (TENANT)',
                    onChanged: _searchOrgs,
                    suffixIcon: const Icon(Icons.search, size: 16),
                  ),
                  if (_orgSearchResults.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AppColors.foundation,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _orgSearchResults.length,
                        itemBuilder: (context, index) {
                          final org = _orgSearchResults[index];
                          return ListTile(
                            dense: true,
                            title: Text(org['name'], style: const TextStyle(fontSize: 12)),
                            onTap: () => setState(() {
                              _selectedOrgId = org['id'];
                              _selectedOrgName = org['name'];
                              _orgSearchResults = [];
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                if (!_isLoginMode) ...[
                  _LabTextField(
                    controller: _nameController,
                    label: 'FULL NAME',
                  ),
                  const SizedBox(height: 16),
                  _LabDropdown(
                    value: _selectedRole,
                    label: 'ACCOUNT TYPE',
                    items: const [
                      DropdownMenuItem(value: 'employee', child: Text('Employee')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    ],
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                  const SizedBox(height: 16),
                ],
                _LabTextField(
                  controller: _emailController,
                  label: 'EMAIL ADDRESS',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _LabTextField(
                  controller: _passwordController,
                  label: 'PASSWORD',
                  obscureText: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!.toUpperCase(),
                    style: AppStyle.label(color: AppColors.warning, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.actionAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text(_isLoginMode ? 'AUTHENTICATE' : 'INITIALIZE ACCOUNT', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Navigate to Onboarding
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrganizationOnboardingScreen()),
                      );
                    },
                    child: Text(
                      'REGISTER NEW ORGANIZATION',
                      style: AppStyle.label(color: AppColors.actionAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _isLoginMode = !_isLoginMode;
                      _error = null;
                    }),
                    child: Text(
                      _isLoginMode ? 'CREATE NEW ACCOUNT' : 'BACK TO SIGN IN',
                      style: AppStyle.label(color: AppColors.dataSecondary, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const _LabTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.suffixIcon,
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
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.foundation,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.actionAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabDropdown extends StatelessWidget {
  final String value;
  final String label;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _LabDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyle.label(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items,
          style: const TextStyle(fontSize: 14, color: AppColors.dataPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.foundation,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
