import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';
import '../pages/employee_dashboard.dart';
import '../pages/routes_page.dart';
import '../pages/warehouse_page.dart';
// import '../pages/machine_editor_page.dart';
import 'sidebar.dart';
import 'main_content.dart';
import '../api/user.dart';
import '../api/users_stub.dart';
import 'overlay_blur_window.dart'; // SignInOverlay & SignUpOverlay
import '../api/employees_repository.dart';
import 'dart:math';

class PagesLayout extends StatefulWidget {
  const PagesLayout({super.key});

  @override
  State<PagesLayout> createState() => _PagesLayoutState();
}

class _PagesLayoutState extends State<PagesLayout> {
  // UI state
  double leftBannerWidth = 150;
  double topBannerHeight = 80;
  int selectedPage = 0;
  bool sidebarExpanded = true;
  bool menuExpanded = false;
  bool showSignInOverlay = false;
  bool showSignUpOverlay = false;
  bool showSettingsOverlay = false;

  // Auth state
  User? currentUser;
  String? employeeId;
  bool isManager = false;
  bool signedIn = false;

  final List<String> pageTitles = ['Dashboard', 'Routes', 'Warehouse'];
  // Use a GlobalKey to call into the RoutesPage state for autorouting
  final GlobalKey _routesKey = GlobalKey();
  List<Widget> get pages {
    final dash = signedIn && !isManager && employeeId != null
        ? EmployeeDashboard(employeeId: employeeId!)
        : const DashboardPage();
    return [
      dash,
      RoutesPage(key: _routesKey, allowAutoRoute: isManager, employeeId: isManager ? null : employeeId),
      isManager ? const WarehousePage.manager() : const WarehousePage(),
    ];
  }

  // Removed unused _handleSidebarMenu

  Future<void> _addEmployeeIfNeeded(String id, String name) async {
    final employees = await EmployeesRepository.loadEmployees();
    final exists = employees.any((e) => e.id == id);
    if (!exists) {
      final usedColors = employees.map((e) => e.color.value).toSet();
      final palette = [
        4294901760, // Red
        4278190335, // Blue
        4278255360, // Green
        4294967040, // Yellow
        4294967295, // White
        4280391411, // Orange
        4283215696, // Purple
        4283788079, // Cyan
        4290822336, // Lime
      ];
      int assigned = palette.firstWhere((c) => !usedColors.contains(c), orElse: () => Random().nextInt(0xFFFFFFFF));
      employees.add(Employee(id: id, name: name, color: Color(assigned)));
      await EmployeesRepository.saveEmployees(employees);
    }
  }

  void _signUp(String name, String email, String password, String role) async {
    final users = UsersStub.users;
    final exists = users.any((u) => u['email'] == email);
    if (exists) return;
    final newUser = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'id': role == 'employee' ? email : '',
    };
    users.add(newUser);
      if (role == 'employee') await _addEmployeeIfNeeded(email, name);
    setState(() {
      showSignUpOverlay = false;
      currentUser = User(newUser['name']!, newUser['email']!);
      isManager = newUser['role'] == 'manager';
        employeeId = newUser['role'] == 'employee' ? newUser['id'] : null;
        signedIn = true;
        // go directly to Dashboard (now index 0)
        selectedPage = 0;
    });
  }

  void _signIn(String email, String password, [String role = 'employee']) async {
    final users = UsersStub.users;
    var user = users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );
    if (user.isEmpty) {
      // Create user if not found (signup-on-login)
      final id = role == 'employee' ? email : '';
      final name = email.split('@').first;
      final newUser = {'email': email, 'name': name, 'password': password, 'role': role, 'id': id};
      users.add(newUser);
      user = newUser;
      if (role == 'employee') await _addEmployeeIfNeeded(id, name);
    }
    setState(() {
      currentUser = User(user['name']!, user['email']!);
      isManager = user['role'] == 'manager';
      employeeId = user['role'] == 'employee' ? user['id'] : null;
      signedIn = true;
      showSignInOverlay = false;
      // show dashboard immediately (now index 0)
      selectedPage = 0;
    });
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (!signedIn)
            ...[
              SignInOverlay(
                onClose: () => setState(() => showSignInOverlay = false),
                onSignIn: (email, password, role) => _signIn(email, password, role),
                onShowSignUp: () => setState(() => showSignUpOverlay = true),
              ),
              if (showSignUpOverlay)
                SignUpOverlay(
                  onClose: () => setState(() => showSignUpOverlay = false),
                  onSignUp: (name, email, password, role) => _signUp(name, email, password, role),
                ),
            ],

          if (signedIn)
            Stack(
              children: [
                // Sidebar for manager on desktop/web
                if (isManager && !isMobile)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Sidebar(
                      width: leftBannerWidth,
                      expanded: sidebarExpanded,
                      selectedPage: selectedPage,
                      menuExpanded: menuExpanded,
                      onPageSelected: (idx) => setState(() => selectedPage = idx),
                      onToggleExpand: () => setState(() => sidebarExpanded = !sidebarExpanded),
                      onToggleMenu: () => setState(() => menuExpanded = !menuExpanded),
                      onSignIn: () => setState(() => showSignInOverlay = true),
                      onSettings: () => setState(() => showSettingsOverlay = true),
                        // Add Machine Editor to sidebar menu for managers
                    ),
                  ),
                Positioned.fill(
                  left: (isManager && !isMobile && sidebarExpanded) ? leftBannerWidth : (isManager && !isMobile ? 64 : 0),
                  child: MainContent(
                    topBannerHeight: isMobile ? 0 : topBannerHeight,
                    pageTitle: pageTitles[selectedPage],
                    page: pages[selectedPage],
                    onBannerHeightChanged: (dy) {
                      if (!isMobile) {
                        setState(() {
                          topBannerHeight += dy;
                          if (topBannerHeight < 40) topBannerHeight = 40;
                          if (topBannerHeight > 200) topBannerHeight = 200;
                        });
                      }
                    },
                    userName: currentUser?.name,
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
                          _NavButton(
                            icon: Icons.dashboard,
                            label: 'Dashboard',
                            selected: selectedPage == 0,
                            onTap: () => setState(() => selectedPage = 0),
                          ),
                          _NavButton(
                            icon: Icons.alt_route,
                            label: 'Routes',
                            selected: selectedPage == 1,
                            onTap: () => setState(() => selectedPage = 1),
                          ),
                          _NavButton(
                            icon: Icons.warehouse,
                            label: 'Warehouse',
                            selected: selectedPage == 2,
                            onTap: () => setState(() => selectedPage = 2),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            tooltip: 'Settings',
                            onPressed: () => setState(() => showSettingsOverlay = true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            tooltip: 'Sign Out',
                            onPressed: () => setState(() => signedIn = false),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

          if (showSettingsOverlay)
            SettingsOverlay(
              onClose: () => setState(() => showSettingsOverlay = false),
            ),
        ],
      ),
    );
  }

}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.label, required this.selected, required this.onTap});
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

class SettingsOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const SettingsOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Add your settings widgets here
                const Text('Setting 1'),
                Switch(value: true, onChanged: (value) {}),
                const Text('Setting 2'),
                Switch(value: false, onChanged: (value) {}),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Handle save settings logic
                  },
                  child: const Text('Save Settings'),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: onClose, child: const Text('Close')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
