import 'package:flutter/material.dart';

class SidebarTab {
  final String label;
  final IconData icon;

  const SidebarTab({required this.label, required this.icon});
}

class Sidebar extends StatelessWidget {
  final double width;
  final bool expanded;
  final int selectedPage;
  final bool menuExpanded;
  final List<SidebarTab> tabs;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleMenu;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  const Sidebar({
    super.key,
    required this.width,
    required this.expanded,
    required this.selectedPage,
    required this.menuExpanded,
    required this.tabs,
    required this.onPageSelected,
    required this.onToggleExpand,
    required this.onToggleMenu,
    required this.onSettings,
    required this.onSignOut,
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
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Column(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  SidebarButton(
                    icon: tabs[i].icon,
                    label: tabs[i].label,
                    expanded: expanded,
                    selected: selectedPage == i,
                    onTap: () => onPageSelected(i),
                  ),
              ],
            ),
          ),
          const Spacer(),
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
                          icon: Icons.settings,
                          label: 'Settings',
                          expanded: expanded,
                          selected: false,
                          onTap: onSettings,
                        ),
                        SidebarButton(
                          icon: Icons.logout,
                          label: 'Sign Out',
                          expanded: expanded,
                          selected: false,
                          onTap: onSignOut,
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
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.black : Colors.black38),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.black54,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
