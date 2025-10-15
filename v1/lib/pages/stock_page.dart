import 'package:flutter/material.dart';
import '../api/employee_routes_repository.dart';
import '../api/mock_vending_api.dart';
import '../api/app_storage.dart' as storage;

class StockPage extends StatefulWidget {
  final String? employeeId;
  const StockPage({super.key, this.employeeId});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  late Future<List<EmployeeRoute>> _routesFuture;
  final Map<String, Map<String, int>> _localNeeded = {}; // machineId -> {sku: needed}
  String? _expandedMachineId;

  @override
  void initState() {
    super.initState();
    _routesFuture = _loadRoutes();
  }

  Future<void> _loadMachineStock(String machineId) async {
    final s = await MockVendingApi().getNeeded(machineId);
    setState(() {
      _localNeeded[machineId] = s;
    });
  }

  Future<void> _changeSku(String machineId, String sku, int delta) async {
  await MockVendingApi().requestNeeded(machineId, sku, delta);
  await _loadMachineStock(machineId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EmployeeRoute>>(
      future: _routesFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final routes = snap.data ?? [];
        final my = routes.where((r) => r.employeeId == (widget.employeeId ?? '')).toList();
        if (my.isEmpty) return Center(child: Text('No assigned machines for this employee.'));
        final stops = my.expand((r) => r.stops).toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('Stock for today', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            for (final s in stops)
              Card(
                child: InkWell(
                  onTap: () async {
                    // Expand only this machine
                    setState(() {
                      _expandedMachineId = _expandedMachineId == s.id ? null : s.id;
                    });
                    if (_expandedMachineId == s.id) await _loadMachineStock(s.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.name),
                          subtitle: Text('ID: ${s.id}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () => _loadMachineStock(s.id),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  await MockVendingApi().fillMachine(s.id);
                                  await _loadMachineStock(s.id);
                                },
                                child: const Text('Fill machine'),
                              ),
                            ],
                          ),
                        ),
                        if (_expandedMachineId == s.id)
                          FutureBuilder<Map<String, int>>(
                            future: _localNeeded.containsKey(s.id) ? Future.value(_localNeeded[s.id]) : MockVendingApi().getNeeded(s.id),
                            builder: (context, snap2) {
                              if (snap2.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(8.0), child: Text('Loading...'));
                              final needed = snap2.data ?? {};
                              if (!_localNeeded.containsKey(s.id)) _localNeeded[s.id] = Map.from(needed);
                              return Column(
                                children: [
                                  for (final sku in MockVendingApi.availableSkus)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(MockVendingApi.skuLabel(sku)), Text(sku, style: Theme.of(context).textTheme.bodySmall)])),
                                          Row(
                                            children: [
                                              // Big '-' request button (increments needed)
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  minimumSize: const Size(56, 40),
                                                ),
                                                child: const Icon(Icons.remove, color: Colors.white),
                                                onPressed: () async {
                                                  await _changeSku(s.id, sku, 1);
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              // Needed count (collated manager view uses same number)
                                              Text('${_localNeeded[s.id]?[sku] ?? 0}', style: Theme.of(context).textTheme.titleLarge),
                                              const SizedBox(width: 8),
                                              // Fill row button (clears needed for this SKU)
                                              OutlinedButton(
                                                onPressed: () async {
                                                  await MockVendingApi().requestNeeded(s.id, sku, -(_localNeeded[s.id]?[sku] ?? 0));
                                                  await _loadMachineStock(s.id);
                                                },
                                                child: const Text('Fill row'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<List<EmployeeRoute>> _loadRoutes() async {
    try {
      final persisted = await storage.getItem('employee_routes');
      if (persisted == null || persisted.isEmpty) return const [];
      return EmployeeRoutesRepository.routesFromJson(persisted);
    } catch (e) {
      return const [];
    }
  }
}
