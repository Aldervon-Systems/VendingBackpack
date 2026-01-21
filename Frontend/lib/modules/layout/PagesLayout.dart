import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import '../dashboard/BusinessMetrics.dart';
import '../dashboard/DashboardHome.dart';
import '../routes/MapInterface.dart';
import '../settings/SettingsMenu.dart';
import '../warehouse/StockScreens.dart';
import '../../core/ui_kit/OverlayBlurWindow.dart';
import 'MainContent.dart';
import 'Sidebar.dart';

class PagesLayout extends StatefulWidget {
  const PagesLayout({super.key});

  @override
  State<PagesLayout> createState() => _PagesLayoutState();
}

class _PagesLayoutState extends State<PagesLayout> {
  double leftBannerWidth = 150;
  double topBannerHeight = 80;
  int selectedPage = 0;
  bool sidebarExpanded = true;
  bool menuExpanded = false;
  bool showSettingsOverlay = false;

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  List<_TabSpec> _buildTabs(SessionManager session) {
    final tabs = <_TabSpec>[];

    tabs.add(
      const _TabSpec(
        label: 'Dashboard',
        icon: Icons.dashboard,
        page: DashboardHome(),
      ),
    );

    tabs.addAll([
      const _TabSpec(label: 'Routes', icon: Icons.alt_route, page: MapInterface()),
      const _TabSpec(label: 'Warehouse', icon: Icons.warehouse, page: StockScreens()),
    ]);

    return tabs;
  }

  void _signOut(SessionManager session) {
    session.logout();
    setState(() {
      menuExpanded = false;
      selectedPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final tabs = _buildTabs(session);
    final safeIndex = selectedPage < tabs.length ? selectedPage : 0;
    if (safeIndex != selectedPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => selectedPage = safeIndex);
      });
    }

    final pageTitle = tabs.isNotEmpty ? tabs[safeIndex].label : 'Dashboard';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (!isMobile)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Sidebar(
                width: leftBannerWidth,
                expanded: sidebarExpanded,
                selectedPage: safeIndex,
                menuExpanded: menuExpanded,
                tabs: tabs.map((t) => SidebarTab(label: t.label, icon: t.icon)).toList(),
                onPageSelected: (idx) => setState(() => selectedPage = idx),
                onToggleExpand: () => setState(() => sidebarExpanded = !sidebarExpanded),
                onToggleMenu: () => setState(() => menuExpanded = !menuExpanded),
                onSettings: () => setState(() {
                  menuExpanded = false;
                  showSettingsOverlay = true;
                }),
                onSignOut: () => _signOut(session),
              ),
            ),
          Positioned.fill(
            left: !isMobile ? (sidebarExpanded ? leftBannerWidth : 64) : 0,
            child: MainContent(
              topBannerHeight: isMobile ? 0 : topBannerHeight,
              pageTitle: pageTitle,
              page: tabs.isNotEmpty ? tabs[safeIndex].page : const SizedBox.shrink(),
              onBannerHeightChanged: (dy) {
                if (!isMobile) {
                  setState(() {
                    topBannerHeight += dy;
                    if (topBannerHeight < 40) topBannerHeight = 40;
                    if (topBannerHeight > 200) topBannerHeight = 200;
                  });
                }
              },
              userName: session.currentUser?.name,
            ),
          ),
          if (isMobile)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      _NavButton(
                        icon: tabs[i].icon,
                        label: tabs[i].label,
                        selected: safeIndex == i,
                        onTap: () => setState(() => selectedPage = i),
                      ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      tooltip: 'Settings',
                      onPressed: () => setState(() => showSettingsOverlay = true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Sign Out',
                      onPressed: () => _signOut(session),
                    ),
                  ],
                ),
              ),
            ),
          if (showSettingsOverlay)
            _SettingsOverlay(
              onClose: () => setState(() => showSettingsOverlay = false),
              child: SettingsMenu(
                onClose: () => setState(() => showSettingsOverlay = false),
              ),
            ),
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

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.white70),
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SettingsOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final Widget child;

  const _SettingsOverlay({required this.onClose, required this.child});

  @override
  Widget build(BuildContext context) {
    return OverlayBlurWindow(
      onTapOutside: onClose,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).round()),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
