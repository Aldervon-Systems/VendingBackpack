// lib/pages/machine_editor_page.dart
import 'package:flutter/material.dart';
import '../api/dashboard_repository.dart';
import '../api/dashboard_store.dart';
import '../api/warehouse_api.dart';
import '../api/inventory_cache.dart';
import '../api/local_data.dart';
import '../components/atoms/app_button.dart';
import '../components/organisms/editable_inventory_list.dart';

class MachineEditorPage extends StatefulWidget {
  const MachineEditorPage({super.key});

  @override
  State<MachineEditorPage> createState() => _MachineEditorPageState();
}

class _MachineEditorPageState extends State<MachineEditorPage> {
  List<Map<String, dynamic>> _machines = [];
  Map<String, dynamic>? _selectedMachine;
  List<Map<String, dynamic>> _skus = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final machines = await DashboardRepository.getMachines();
      
      setState(() {
        _machines = machines;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadSkusForMachine(Map<String, dynamic> machine) async {
    try {
      setState(() {
        _selectedMachine = machine;
        _loading = true;
      });

      final mid = machine['id'] ?? machine['name'];
      
      // Load directly from backend instead of cache to get fresh data
      final inventoryData = await LocalData.inventory();
      final machineInventoryRaw = inventoryData[mid];
      
      List<Map<String, dynamic>> machineInventory = [];
      if (machineInventoryRaw != null) {
        if (machineInventoryRaw is List) {
          machineInventory = machineInventoryRaw
              .where((item) => item is Map)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      }
      
      setState(() {
        _skus = machineInventory;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onAddSku() {
    setState(() {
      _skus.add({'sku': '', 'name': '', 'qty': 0, 'cap': 1});
    });
  }

  void _onDeleteSku(int index) {
    if (index >= 0 && index < _skus.length) {
      setState(() => _skus.removeAt(index));
    }
  }

  Future<void> _save() async {
    if (_selectedMachine == null) return;

    final mid = _selectedMachine!['id'] ?? _selectedMachine!['name'];

    final sanitized = _skus.where((s) => (s['sku'] ?? '').toString().trim().isNotEmpty).map((raw) {
      final sku = (raw['sku'] ?? '').toString().trim();
      final name = (raw['name'] ?? '').toString().trim();
      // Preserve existing quantity from backend data, don't let user edit it
      final qty = raw['qty'] is num ? (raw['qty'] as num).toInt() : 0;
      final cap = raw['cap'] is num ? (raw['cap'] as num).toInt() : int.tryParse(raw['cap']?.toString() ?? '') ?? 1;
      return {'sku': sku, 'name': name.isEmpty ? sku : name, 'qty': qty, 'cap': cap > 0 ? cap : 1};
    }).toList();

    setState(() => _saving = true);

    try {
      final success = await WarehouseApi.updateMachineInventory(mid, sanitized);
      if (!success) throw Exception('Server rejected update');

      // Clear cache and dashboard snapshot to force fresh reload when dashboard is viewed
      InventoryCache.instance.clearCache();
      DashboardStore.instance.clearSnapshot();

      if (mounted) {
        setState(() {
          _skus = sanitized.map((e) => Map<String, dynamic>.from(e)).toList();
          _saving = false;
        });
        
        // Show success message and navigate back immediately
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully!'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Navigate back to dashboard immediately
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 16), AppButton.primary(label: 'Retry', onPressed: _load)]));

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedMachine != null
          ? 'Editing: ${_selectedMachine!['name']}'
          : 'Machine Editor'),
        actions: [
          if (_selectedMachine != null && !_saving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: 'Save changes',
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedMachine == null)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Select a machine to edit:'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _machines.length,
                      itemBuilder: (context, index) {
                        final machine = _machines[index];
                        return ListTile(
                          title: Text(machine['name'] ?? machine['id'] ?? 'Unknown'),
                          subtitle: Text('ID: ${machine['id'] ?? machine['name']}'),
                          onTap: () => _loadSkusForMachine(machine),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Editing: ${_selectedMachine!['name']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: EditableInventoryList(
                        items: _skus,
                        onDelete: _onDeleteSku,
                        onAdd: _onAddSku,
                        onItemsChanged: () => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
