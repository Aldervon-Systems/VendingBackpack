import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final double width;
  final bool expanded;
  final int selectedPage;
  final bool menuExpanded;
  final Function(int) onPageSelected;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleMenu;
  final VoidCallback? onSignIn;
  final VoidCallback? onSettings;

  const Sidebar({
    super.key,
    required this.width,
    required this.expanded,
    required this.selectedPage,
    required this.menuExpanded,
    required this.onPageSelected,
    required this.onToggleExpand,
    required this.onToggleMenu,
    this.onSignIn,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? width : 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          right: BorderSide(color: Colors.black12, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Expand/collapse button
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: AnimatedRotation(
                  turns: expanded ? 0.0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.arrow_left),
                ),
                tooltip: expanded ? 'Collapse' : 'Expand',
                onPressed: onToggleExpand,
              ),
            ),
          ),
          // Top buttons
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Column(
              children: [
                SidebarButton(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  expanded: expanded,
                  selected: selectedPage == 0,
                  onTap: () => onPageSelected(0),
                ),
                SidebarButton(
                  icon: Icons.alt_route,
                  label: 'Routes',
                  expanded: expanded,
                  selected: selectedPage == 1,
                  onTap: () => onPageSelected(1),
                ),
                SidebarButton(
                  icon: Icons.warehouse,
                  label: 'Warehouse',
                  expanded: expanded,
                  selected: selectedPage == 2,
                  onTap: () => onPageSelected(2),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom menu button and expandable section
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0, top: 8.0),
            child: Column(
              children: [
                SidebarButton(
                  icon: Icons.menu,
                  label: 'Menu',
                  expanded: expanded,
                  selected: false,
                  onTap: onToggleMenu,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: menuExpanded ? (expanded ? 112 : 80) : 0,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SidebarButton(
                          icon: Icons.login,
                          label: 'Sign In',
                          expanded: expanded,
                          selected: false,
                          onTap: onSignIn ?? () {},
                        ),
                        SidebarButton(
                          icon: Icons.settings,
                          label: 'Settings',
                          expanded: expanded,
                          selected: false,
                          onTap: onSettings ?? () {},
                        ),
                      ],
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

class SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  const SidebarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: expanded ? 16 : 0,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.black12 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: expanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.black : Colors.black38),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.black54,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
