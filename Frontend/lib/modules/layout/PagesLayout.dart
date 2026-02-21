import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/SessionManager.dart';
import '../dashboard/DashboardHome.dart';
import '../routes/MapInterface.dart';
import '../settings/SettingsMenu.dart';
import '../warehouse/StockScreens.dart';
import '../../core/ui_kit/OverlayBlurWindow.dart';
import '../../core/styles/AppStyle.dart';
import 'MainContent.dart';
import 'Sidebar.dart';

import '../auth/OrganizationAdminModal.dart';

import '../routes/RoutePlanner.dart';

class PagesLayout extends StatefulWidget {
  const PagesLayout({super.key});

  @override
  State<PagesLayout> createState() => _PagesLayoutState();
}

class _PagesLayoutState extends State<PagesLayout> {
  double leftBannerWidth = 240;
  int selectedPage = 0;
  bool showSettingsOverlay = false;

  bool get isMobile => MediaQuery.of(context).size.width < 768; // Slightly larger break for Clean Lab feel

  List<_TabSpec> _buildTabs(SessionManager session) {
    final tabs = <_TabSpec>[];
    tabs.add(const _TabSpec(label: 'Dashboard', icon: Icons.grid_view_outlined, page: DashboardHome()));
    tabs.add(const _TabSpec(label: 'Routes', icon: Icons.map_outlined, page: MapInterface()));
    tabs.add(const _TabSpec(label: 'Warehouse', icon: Icons.inventory_2_outlined, page: StockScreens()));
    
    // Add Admin tab for managers
    if (session.isManager) {
      tabs.add(_TabSpec(
        label: 'Admin', 
        icon: Icons.admin_panel_settings_outlined, 
        page: const Center(child: Text('Admin Dashboard Loading...')), // Placeholder since we'll trigger a modal for now or we could make it a page
        onTap: (context) {
          showDialog(
            context: context,
            builder: (context) => const OrganizationAdminModal(),
          );
        }
      ));
    }
    
    return tabs;
  }

  void _signOut(SessionManager session) {
    session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final tabs = _buildTabs(session);
    final safeIndex = selectedPage < tabs.length ? selectedPage : 0;
    
    final pageTitle = tabs.isNotEmpty ? tabs[safeIndex].label : 'Dashboard';

    // Initialize/Sync the global RoutePlanner with the current session context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final planner = context.read<RoutePlanner>();
        final restrictedId = !session.isManager || session.effectiveRole == 'employee' 
            ? session.currentUser?.id.toString() 
            : null;
        
        if (planner.restrictedEmployeeId != restrictedId) {
          planner.setRestrictedId(restrictedId);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.foundation,
      body: Stack(
        children: [
          Row(
            children: [
              if (!isMobile)
                Sidebar(
                  width: leftBannerWidth,
                  expanded: false, // Will expand on hover internally
                  selectedPage: safeIndex,
                  tabs: tabs.map((t) => SidebarTab(label: t.label, icon: t.icon)).toList(),
                  onPageSelected: (idx) {
                    if (tabs[idx].onTap != null) {
                      tabs[idx].onTap!(context);
                    } else {
                      setState(() => selectedPage = idx);
                    }
                  },
                  onSettings: () => setState(() => showSettingsOverlay = true),
                  onSignOut: () => _signOut(session),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!isMobile)
                      _Header(title: pageTitle, userName: session.currentUser?.name),
                    Expanded(
                      child: tabs.isNotEmpty ? tabs[safeIndex].page : const SizedBox.shrink(),
                    ),
                    if (isMobile) const SizedBox(height: 72), // Space for bottom nav
                  ],
                ),
              ),
            ],
          ),
          if (isMobile)
            _MobileNav(
              tabs: tabs,
              currentIndex: safeIndex,
              onTap: (idx) {
                if (tabs[idx].onTap != null) {
                  tabs[idx].onTap!(context);
                } else {
                  setState(() => selectedPage = idx);
                }
              },
              onSettings: () => setState(() => showSettingsOverlay = true),
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

class _Header extends StatelessWidget {
  final String title;
  final String? userName;
  const _Header({required this.title, this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.transparent, // Foundation handled by Scaffold
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppStyle.label(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dataPrimary)),
          if (userName != null)
            Row(
              children: [
                Text(userName!, style: AppStyle.label(fontWeight: FontWeight.w600, color: AppColors.dataPrimary)),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.border,
                  child: Icon(Icons.person_outline, size: 16, color: AppColors.dataSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  final List<_TabSpec> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSettings;

  const _MobileNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.dataPrimary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < tabs.length; i++)
              _MobileNavItem(
                icon: tabs[i].icon,
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
              ),
            _MobileNavItem(
              icon: Icons.settings_outlined,
              isSelected: false,
              onTap: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileNavItem({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        color: isSelected ? AppColors.actionAccent : AppColors.dataSecondary,
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  final Widget page;
  final Function(BuildContext)? onTap;
  const _TabSpec({required this.label, required this.icon, required this.page, this.onTap});
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
        padding: const EdgeInsets.all(24),
        decoration: AppStyle.surfaceCard,
        child: child,
      ),
    );
  }
}
