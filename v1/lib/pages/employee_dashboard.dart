// lib/pages/employee_dashboard.dart
import 'package:flutter/material.dart';
import '../api/locations_repository.dart';
import '../api/local_data.dart';
import '../api/dashboard_store.dart';
import '../api/inventory_cache.dart';
import '../api/employee_routes_repository.dart';
import '../components/organisms/route_stops_list.dart';
import '../components/atoms/app_button.dart';

class EmployeeDashboard extends StatefulWidget {
  final String employeeId;
  const EmployeeDashboard({super.key, required this.employeeId});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  List<VmLocation> _route = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    DashboardStore.instance.addListener(_onStoreChange);
    InventoryCache.instance.addListener(_onCacheChange);
    // Listen for persisted/generated routes so the employee view updates when
    // the manager publishes routes after this screen has already loaded.
    EmployeeRoutesRepository.lastGenerated.addListener(_onPersistedRoutesChanged);
    // Start by attempting to load persisted routes and then load the initial route.
    EmployeeRoutesRepository.loadPersistedRoutes();
    EmployeeRoutesRepository.startAutoRefresh();
    _loadRoute();
  }

  @override
  void dispose() {
    InventoryCache.instance.removeListener(_onCacheChange);
    DashboardStore.instance.removeListener(_onStoreChange);
    EmployeeRoutesRepository.lastGenerated.removeListener(_onPersistedRoutesChanged);
    super.dispose();
  }

  void _onPersistedRoutesChanged() {
    final assigned = EmployeeRoutesRepository.lastGenerated.value;
    if (assigned == null) return;
    final needle = widget.employeeId.toString().toLowerCase();
    final match = assigned.where((r) => r.employeeId.toString().toLowerCase() == needle).toList();
    if (match.isNotEmpty) {
      if (mounted) setState(() { _route = List<VmLocation>.from(match.first.stops); });
    }
  }

  void _onStoreChange() => setState(() {});
  void _onCacheChange() => setState(() {});

  Future<void> _loadRoute() async {
    setState(() => _loading = true);
    await DashboardStore.instance.ensureLoaded();
    
    try {
      // Ensure we have attempted to load persisted routes so we can prefer assigned routes.
      await EmployeeRoutesRepository.loadPersistedRoutes();
      // Prefer assigned route from EmployeeRoutesRepository if available
      final assigned = EmployeeRoutesRepository.lastGenerated.value;
      if (assigned != null) {
        final needle = widget.employeeId.toString().toLowerCase();
        final match = assigned.where((r) => r.employeeId.toString().toLowerCase() == needle).toList();
        if (match.isNotEmpty) {
          if (mounted) setState(() { _route = List<VmLocation>.from(match.first.stops); _loading = false; });
          return;
        }
      }

      // Fallback: show all locations (manager may not have assigned routes yet)
      final allLocations = await LocationsRepository.load();
      if (mounted) {
        setState(() { _route = allLocations; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading route: $e')));
      }
    }
  }

  Future<void> _refreshInventory() async {
    setState(() => _loading = true);
    await DashboardStore.instance.refresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleFillItem(String machineId, String sku) async {
    // Optimistically update shared cache so manager and other employee views
    // immediately see the filled SKU.
    try {
      InventoryCache.instance.fillSku(machineId, sku);
    } catch (_) {}

    final success = await LocalData.postFill(machineId, sku: sku);
    if (success && mounted) {
      // Refresh authoritative data from backend to ensure counts and warehouse
      // adjustments are reflected in dashboards.
      await DashboardStore.instance.refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item filled!')));
    } else if (mounted) {
      // If POST failed, refresh to revert optimistic change and inform user
      await DashboardStore.instance.refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill failed')));
    }
  }

  Future<void> _handleFillAll(String machineId) async {
    // Optimistically update shared cache so UI shows filled row immediately.
    try {
      InventoryCache.instance.fillRow(machineId);
    } catch (_) {}

    final success = await LocalData.postFill(machineId, action: 'row');
    if (success && mounted) {
      await DashboardStore.instance.refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All items filled!')));
    } else if (mounted) {
      // Revert optimistic update by refreshing authoritative data
      await DashboardStore.instance.refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Dashboard - \${widget.employeeId}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppButton.icon(
              icon: Icons.refresh,
              onPressed: _loading ? null : _refreshInventory,
              tooltip: 'Refresh Inventory',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RouteStopsList(
              stops: _route,
              onFillItem: _handleFillItem,
              onFillAll: _handleFillAll,
            ),
    );
  }
}
