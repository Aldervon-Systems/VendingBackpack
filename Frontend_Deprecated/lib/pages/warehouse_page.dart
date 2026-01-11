import 'package:flutter/material.dart';
import 'warehouse_scan_flow.dart';
import '../api/warehouse_api.dart';
import '../api/dashboard_store.dart';
import '../api/inventory_cache.dart';

class WarehousePage extends StatefulWidget {
  final bool isManager;
  const WarehousePage({super.key, this.isManager = false});
  const WarehousePage.manager({super.key}) : isManager = true;

  @override
  State<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  String? _lastBarcode;
  Map<String, dynamic>? _item;
  bool _loading = false;
  String? _error;
  final GlobalKey<_ManagerInventoryListState> _inventoryKey = GlobalKey();

  Future<void> _onBarcodeScanned(String barcode) async {
    setState(() {
      _lastBarcode = barcode;
      _loading = true;
      _item = null;
      _error = null;
    });
    try {
      final item = await WarehouseApi.getItem(barcode);
      setState(() {
        _item = item;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isManager) {
      return _ManagerInventoryList(key: _inventoryKey);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Warehouse')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WarehouseScanFlow(
                onBarcodeScanned: _onBarcodeScanned,
              ),
              if (_loading) const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (_lastBarcode != null && !_loading && _item == null && _error == null)
                NewItemFlow(barcode: _lastBarcode!, onCancel: () => setState(() => _lastBarcode = null), onItemAdded: () => _inventoryKey.currentState?.reload()),
              if (_item != null)
                CheckInOutFlow(item: _item!),
            ],
          ),
        ),
      ),
    );
  }

}

class _ManagerInventoryList extends StatefulWidget {
  const _ManagerInventoryList({super.key});

  @override
  State<_ManagerInventoryList> createState() => _ManagerInventoryListState();
}

class _ManagerInventoryListState extends State<_ManagerInventoryList> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await DashboardStore.instance.refresh();
      final slots = InventoryCache.instance.inventory['warehouse'] ?? <Map<String, dynamic>>[];
      final items = slots.map((slot) => {
        'sku': slot['sku']?.toString() ?? '',
        'name': slot['name'] ?? slot['sku'] ?? '',
        'qty': slot['qty'] ?? 0,
        'barcode': slot['barcode'] ?? slot['sku'] ?? '',
      }).toList();
      setState(() {
        _items = items;
        _filtered = _items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _items = [];
        _filtered = [];
        _loading = false;
      });
    }
  }

  void reload() {
    _load();
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filtered = _items.where((item) =>
        (item['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warehouse Inventory')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearch,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final item = _filtered[i];
                      return ListTile(
                        leading: item['photo_url'] != null
                            ? Image.network(item['photo_url'], width: 40, height: 40, fit: BoxFit.cover)
                            : const Icon(Icons.inventory),
                        title: Text(item['name'] ?? 'Unknown'),
                        subtitle: Text('SKU: ${item['barcode'] ?? ''}  Qty: ${item['qty'] ?? 0}'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class NewItemFlow extends StatefulWidget {
  final String barcode;
  final VoidCallback? onCancel;
  final VoidCallback? onItemAdded;
  const NewItemFlow({super.key, required this.barcode, this.onCancel, this.onItemAdded});

  @override
  State<NewItemFlow> createState() => _NewItemFlowState();
}

class _NewItemFlowState extends State<NewItemFlow> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  int _step = 0;
  bool _saving = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add New Item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Barcode: ${widget.barcode}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            if (_step == 0) ...[
              const Text('Step 1: Enter product name'),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Back'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ] else if (_step == 1) ...[
              const Text('Step 2: Enter initial quantity'),
              TextField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Initial quantity', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('Back'),
                  ),
                  ElevatedButton(
                    onPressed: _saving ? null : () async {
                      setState(() { _saving = true; _error = null; });
                      final ok = await WarehouseApi.addItem({
                        'barcode': widget.barcode,
                        'name': _nameController.text,
                        'photo_url': null,
                        'locations': [],
                        'qty': int.tryParse(_qtyController.text) ?? 0,
                      });
                      setState(() { _saving = false; });
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added!')));
                        widget.onItemAdded?.call();
                        widget.onCancel?.call();
                      } else {
                        setState(() { _error = 'Failed to add item'; });
                      }
                    },
                    child: _saving ? const CircularProgressIndicator() : const Text('Finish'),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckInOutFlow extends StatefulWidget {
  final Map<String, dynamic> item;
  const CheckInOutFlow({super.key, required this.item});
  @override
  State<CheckInOutFlow> createState() => _CheckInOutFlowState();
}

class _CheckInOutFlowState extends State<CheckInOutFlow> {
  final _qtyController = TextEditingController();
  final _locationController = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Item: ${widget.item['name']} (${widget.item['barcode']})', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Qty: ${widget.item['qty']}'),
            TextField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saving ? null : () async {
                    setState(() { _saving = true; _error = null; });
                    final ok = await WarehouseApi.checkIn(
                      widget.item['barcode'],
                      int.tryParse(_qtyController.text) ?? 0,
                      _locationController.text,
                    );
                    setState(() { _saving = false; });
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in!')));
                    } else {
                      setState(() { _error = 'Failed to check in'; });
                    }
                  },
                  child: _saving ? const CircularProgressIndicator() : const Text('Check In'),
                ),
                ElevatedButton(
                  onPressed: _saving ? null : () async {
                    setState(() { _saving = true; _error = null; });
                    final ok = await WarehouseApi.checkOut(
                      widget.item['barcode'],
                      int.tryParse(_qtyController.text) ?? 0,
                      _locationController.text,
                    );
                    setState(() { _saving = false; });
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked out!')));
                    } else {
                      setState(() { _error = 'Failed to check out'; });
                    }
                  },
                  child: _saving ? const CircularProgressIndicator() : const Text('Check Out'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
