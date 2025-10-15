// lib/pages/dashboard_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api/dashboard_store.dart';
import '../api/inventory_cache.dart';
import '../components/organisms/dashboard_metrics.dart';
import '../components/molecules/machine_stop_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    DashboardStore.instance.addListener(_onStore);
    InventoryCache.instance.addListener(_onCacheDebug);
    DashboardStore.instance.ensureLoaded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure data is loaded when returning to this page
    DashboardStore.instance.ensureLoaded();
  }

  @override
  void dispose() {
    InventoryCache.instance.removeListener(_onCacheDebug);
    DashboardStore.instance.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    setState(() {});
  }

  void _onCacheDebug() {
    if (kDebugMode) {
      print('[DashboardPage] _onCache triggered, inventory machines=\${InventoryCache.instance.inventory.keys.length}');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = DashboardStore.instance;
    final snapshot = store.snapshot;

    if (snapshot == null) {
      if (store.error != null && !store.isLoading) {
        return Center(child: Text('Error: \${store.error}'));
      }
      return const Center(child: CircularProgressIndicator());
    }

    final machines = snapshot.machines;
    final locations = snapshot.locations;

    final locMap = <String, List<double>>{};
    final nameMap = <String, String>{};
    for (final r in locations) {
      if (r is Map) {
        final id = (r['id'] ?? r['name'] ?? '').toString();
        final lat = (r['lat'] is num) ? (r['lat'] as num).toDouble() : null;
        final lng = (r['lng'] is num) ? (r['lng'] as num).toDouble() : null;
        final name = (r['name'] ?? '').toString();
        if (id.isNotEmpty && lat != null && lng != null) locMap[id] = [lat, lng];
        if (id.isNotEmpty && name.isNotEmpty) nameMap[id] = name;
      }
    }

    final bool showLoadingOverlay = store.isLoading;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              DashboardMetrics(snapshot: snapshot),
              const SizedBox(height: 16),
              
              ...machines.map((m) {
                final mid = m is String ? m : (m is Map ? (m['id'] ?? m['machineId'] ?? '').toString() : m.toString());
                final onlineSet = snapshot.dashboard.machinesOnlineIds;
                final isOnline = onlineSet.contains(mid);
                // Prefer the location name (from locations) for display; fall back to machine 'name' field or id
                String? machineName;
                if (m is Map) {
                  machineName = (m['name'] ?? m['displayName'] ?? '').toString();
                  if (machineName.isEmpty) machineName = null;
                }
                machineName = machineName ?? nameMap[mid];
                return MachineStopCard(
                  machineId: mid,
                  machineName: machineName,
                  subtitle: null,
                  showFillButtons: false,
                  onFillItem: null,
                  onFillAll: null,
                  iconColor: isOnline ? Colors.green : Colors.grey,
                );
              }).toList(),
            ],
          ),
        ),
        
        if (showLoadingOverlay)
          Positioned(
            bottom: 24,
            right: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              ),
            ),
          ),
      ],
    );
  }
}
