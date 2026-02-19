import 'package:flutter/material.dart';
import '../../core/styles/AppStyle.dart';

class SidebarTab {
  final String label;
  final IconData icon;

  const SidebarTab({required this.label, required this.icon});
}

class Sidebar extends StatefulWidget {
  final double width;
  final bool expanded;
  final int selectedPage;
  final List<SidebarTab> tabs;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  const Sidebar({
    super.key,
    required this.width,
    required this.expanded,
    required this.selectedPage,
    required this.tabs,
    required this.onPageSelected,
    required this.onSettings,
    required this.onSignOut,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // We use the hover state to auto-expand for the "Clean Lab" feel
    final bool effectivelyExpanded = widget.expanded || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: effectivelyExpanded ? widget.width : 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            right: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _LogoEffect(expanded: effectivelyExpanded),
            const SizedBox(height: 32),
            for (var i = 0; i < widget.tabs.length; i++)
              _SidebarNavItem(
                icon: widget.tabs[i].icon,
                label: widget.tabs[i].label,
                isSelected: widget.selectedPage == i,
                expanded: effectivelyExpanded,
                onTap: () => widget.onPageSelected(i),
              ),
            const Spacer(),
            _SidebarNavItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isSelected: false,
              expanded: effectivelyExpanded,
              onTap: widget.onSettings,
            ),
            _SidebarNavItem(
              icon: Icons.logout_outlined,
              label: 'Sign Out',
              isSelected: false,
              expanded: effectivelyExpanded,
              onTap: widget.onSignOut,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LogoEffect extends StatelessWidget {
  final bool expanded;
  const _LogoEffect({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.dataPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            const Text(
              'LAB v3.0',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.5,
                color: AppColors.dataPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.foundation : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: expanded ? 12 : 0),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.actionAccent : AppColors.dataSecondary,
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: AppStyle.label(
                  color: isSelected ? AppColors.dataPrimary : AppColors.dataSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
