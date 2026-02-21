import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/styles/AppStyle.dart';
import './SessionManager.dart';
import '../dashboard/BusinessMetrics.dart';
import '../routes/RoutePlanner.dart';

class OrganizationAdminModal extends StatefulWidget {
  const OrganizationAdminModal({super.key});

  @override
  State<OrganizationAdminModal> createState() => _OrganizationAdminModalState();
}

class _OrganizationAdminModalState extends State<OrganizationAdminModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _vinController = TextEditingController();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  List<String> _localWhitelist = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _addMachine() async {
    if (_vinController.text.isEmpty || _nameController.text.isEmpty) return;
    
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      setState(() => _error = 'Invalid latitude or longitude');
      return;
    }

    final orgId = context.read<SessionManager>().currentUser?.organizationId ?? 'unknown_org';
    debugPrint('CMD MACHINE_ADD START org=$orgId vin=${_vinController.text} name=${_nameController.text} lat=$lat lng=$lng');

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<SessionManager>().addMachine(
        vin: _vinController.text,
        name: _nameController.text,
        lat: lat,
        lng: lng,
      );
      
      // Refresh global network state
      if (mounted) {
        await context.read<RoutePlanner>().loadRoutes();
        await context.read<BusinessMetrics>().loadData();
      }

      debugPrint('CMD MACHINE_ADD OK org=$orgId vin=${_vinController.text}');

      _vinController.clear();
      _nameController.clear();
      _latController.clear();
      _lngController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Machine added successfully')),
        );
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      debugPrint('CMD MACHINE_ADD FAIL org=$orgId error=$message');
      setState(() => _error = message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWhitelist() async {
    setState(() => _isLoading = true);
    try {
      await context.read<SessionManager>().updateWhitelist(_localWhitelist);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Whitelist updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.foundation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ORGANIZATION ADMIN', style: AppStyle.label(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.actionAccent,
              unselectedLabelColor: AppColors.dataSecondary,
              indicatorColor: AppColors.actionAccent,
              tabs: const [
                Tab(text: 'MACHINES'),
                Tab(text: 'WHITELIST'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMachinesTab(),
                  _buildWhitelistTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachinesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REGISTER NEW MACHINE', style: AppStyle.label(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Link hardware to your organization network.', style: AppStyle.label(fontSize: 12, color: AppColors.dataSecondary)),
          const SizedBox(height: 24),
          _LabTextField(controller: _nameController, label: 'MACHINE NAME (E.G. UNIT-01)'),
          const SizedBox(height: 16),
          _LabTextField(controller: _vinController, label: 'VIN NUMBER'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _LabTextField(controller: _latController, label: 'LATITUDE')),
              const SizedBox(width: 8),
              Expanded(child: _LabTextField(controller: _lngController, label: 'LONGITUDE')),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _latController.text = '42.3601';
                _lngController.text = '-71.0589';
              });
            },
            icon: const Icon(Icons.location_on, size: 14),
            label: Text('USE DEMO HUB COORDS', style: AppStyle.label(fontSize: 10, color: AppColors.actionAccent)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionAccent),
              onPressed: _isLoading ? null : _addMachine,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('REGISTER AS NETWORK NODE', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          if (_error != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildWhitelistTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MANAGE EMPLOYEE WHITELIST', style: AppStyle.label(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Only these emails will be allowed to signup under your organization.', style: AppStyle.label(fontSize: 12, color: AppColors.dataSecondary)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _LabTextField(controller: _emailController, label: 'EMAIL ADDRESS')),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_emailController.text.isNotEmpty) {
                    setState(() {
                      _localWhitelist.add(_emailController.text);
                      _emailController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add_circle, color: AppColors.actionAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.builder(
                itemCount: _localWhitelist.length,
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  title: Text(_localWhitelist[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: () => setState(() => _localWhitelist.removeAt(index)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.dataPrimary),
              onPressed: _isLoading ? null : _saveWhitelist,
              child: Text('SAVE WHITELIST', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(_error!, style: AppStyle.label(color: AppColors.warning, fontWeight: FontWeight.bold)),
    );
  }
}

class _LabTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _LabTextField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyle.label(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.foundation,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }
}
