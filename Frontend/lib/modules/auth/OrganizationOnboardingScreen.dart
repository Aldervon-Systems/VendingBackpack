import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/styles/AppStyle.dart';
import './SessionManager.dart';

class OrganizationOnboardingScreen extends StatefulWidget {
  const OrganizationOnboardingScreen({super.key});

  @override
  State<OrganizationOnboardingScreen> createState() => _OrganizationOnboardingScreenState();
}

class _OrganizationOnboardingScreenState extends State<OrganizationOnboardingScreen> {
  final _stepController = PageController();
  int _currentStep = 0;

  // Step 1: Manager Credentials
  final _managerEmailController = TextEditingController();
  final _managerPasswordController = TextEditingController();

  // Step 2: Org Details
  final _orgNameController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  // Step 3: Whitelist
  final _whitelistController = TextEditingController();
  final List<String> _whitelist = [];

  // Result
  String? _totpSeed;
  String? _totpUri;
  bool _isLoading = false;
  String? _error;

  void _nextStep() {
    if (_currentStep < 2) {
      _stepController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _finalizeOnboarding();
    }
  }

  Future<void> _finalizeOnboarding() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await context.read<SessionManager>().createOrganization(
        name: _orgNameController.text,
        managerEmail: _managerEmailController.text,
        managerPassword: _managerPasswordController.text,
        adminPassword: _adminPasswordController.text,
        whitelist: _whitelist,
      );

      setState(() {
        _totpSeed = result['totp_seed'];
        _totpUri = result['totp_uri'];
        _currentStep = 3;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foundation,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dataPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ORG ONBOARDING', style: AppStyle.label(fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 48),
              Expanded(
                child: PageView(
                  controller: _stepController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(4, (index) {
        bool active = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.actionAccent : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MANAGER VALIDATION', style: AppStyle.label(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Only active Managers can provision new Organizations.', style: AppStyle.label(color: AppColors.dataSecondary)),
        const SizedBox(height: 32),
        _LabTextField(controller: _managerEmailController, label: 'MANAGER EMAIL'),
        const SizedBox(height: 16),
        _LabTextField(controller: _managerPasswordController, label: 'PERSONAL PASSWORD', obscureText: true),
        if (_error != null) _buildError(),
        const Spacer(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ORGANIZATION DETAILS', style: AppStyle.label(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Define your corporate entity and administrative keys.', style: AppStyle.label(color: AppColors.dataSecondary)),
        const SizedBox(height: 32),
        _LabTextField(controller: _orgNameController, label: 'ORGANIZATION NAME'),
        const SizedBox(height: 16),
        _LabTextField(controller: _adminPasswordController, label: 'ORG ADMIN PASSWORD (MASTER KEY)', obscureText: true),
        const Spacer(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACCESS CONTROL LIST (WHITELIST)', style: AppStyle.label(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Add authorized email addresses for this Organization.', style: AppStyle.label(color: AppColors.dataSecondary)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _LabTextField(controller: _whitelistController, label: 'ADD EMAIL')),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_whitelistController.text.isNotEmpty) {
                  setState(() {
                    _whitelist.add(_whitelistController.text);
                    _whitelistController.clear();
                  });
                }
              },
              icon: const Icon(Icons.add_circle, color: AppColors.actionAccent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _whitelist.length,
            itemBuilder: (context, index) => ListTile(
              dense: true,
              title: Text(_whitelist[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete, size: 16),
                onPressed: () => setState(() => _whitelist.removeAt(index)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNextButton(label: 'PROVISION ORGANIZATION'),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 48),
        const SizedBox(height: 24),
        Text('IDENTITY SYNC (2FA)', style: AppStyle.label(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Scan this seed in your Authenticator app. This is your hardware-linked trust factor.', style: AppStyle.label(color: AppColors.dataSecondary)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.foundation,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text('TOTP SEED:', style: AppStyle.label(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SelectableText(_totpSeed ?? 'ERROR', style: const TextStyle(fontFamily: 'Courier', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.actionAccent)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Save this seed securely. You will need it to verify administrative changes.', style: AppStyle.label(fontSize: 12, color: AppColors.warning)),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionAccent),
            onPressed: () => Navigator.pop(context),
            child: Text('COMPLETE SETUP', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton({String label = 'CONTINUE'}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionAccent),
        onPressed: _isLoading ? null : _nextStep,
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label, style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(_error!.toUpperCase(), style: AppStyle.label(color: AppColors.warning, fontWeight: FontWeight.bold)),
    );
  }
}

class _LabTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;

  const _LabTextField({required this.controller, required this.label, this.obscureText = false});

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
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.foundation,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
