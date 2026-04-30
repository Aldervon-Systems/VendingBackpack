import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import 'BusinessMetrics.dart';
import '../settings/SettingsMenu.dart';
import 'widgets/DashboardMetrics.dart';
import 'widgets/MachineStopCard.dart';

// Placeholder for other modules
import '../routes/MapInterface.dart';
import '../warehouse/StockScreens.dart';

class OverviewScreens extends StatefulWidget {
  const OverviewScreens({super.key});

  @override
  State<OverviewScreens> createState() => _OverviewScreensState();
}

class _OverviewScreensState extends State<OverviewScreens> {
  int _selectedIndex = 0;

  void _showSettingsMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const SettingsMenu(),
    );
  }

  List<_TabSpec> _buildTabs(SessionManager session) {
    final List<_TabSpec> tabs = [];

    if (session.effectiveRole == 'manager') {
      tabs.add(
        _TabSpec(
          label: 'Dashboard',
          icon: Icons.dashboard,
          page: ChangeNotifierProvider(
            create: (_) => BusinessMetrics()..loadData(),
            child: const _DashboardHome(),
          ),
        ),
      );
    }

    tabs.addAll([
      const _TabSpec(label: 'Routes', icon: Icons.map, page: MapInterface()),
      const _TabSpec(label: 'Warehouse', icon: Icons.inventory, page: StockScreens()),
    ]);

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final tabs = _buildTabs(session);
    final safeIndex = _selectedIndex < tabs.length ? _selectedIndex : 0;

    if (safeIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedIndex = safeIndex);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VendingBackpack'),
        actions: [
          if (session.isManager)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsMenu,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SessionManager>().logout(),
          ),
        ],
      ),
      body: tabs[safeIndex].page,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        items: [
          for (final tab in tabs)
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  final Widget page;

  const _TabSpec({required this.label, required this.icon, required this.page});
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final metrics = context.watch<BusinessMetrics>();
    final user = context.read<SessionManager>().currentUser;

    if (metrics.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null)
          Text('Welcome, ${user.name}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        DashboardMetrics(
          totalMachines: metrics.totalMachines,
          onlineMachines: metrics.onlineMachines,
          revenueToday: metrics.revenueToday,
        ),
        const SizedBox(height: 16),
        const Text('Machines Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...metrics.inventory.map((snapshot) {
          return MachineStopCard(
            machineId: snapshot.machineId,
            machineName: snapshot.machineName,
            items: snapshot.items,
            isOnline: true,
          );
        }),
      ],
    );
  }
}
