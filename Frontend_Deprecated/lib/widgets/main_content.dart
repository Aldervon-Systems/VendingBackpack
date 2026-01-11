import 'package:flutter/material.dart';
import '../api/dashboard_store.dart';

class MainContent extends StatefulWidget {
  final double topBannerHeight;
  final String pageTitle;
  final Widget page;
  final ValueChanged<double> onBannerHeightChanged;
  final String? userName;

  const MainContent({
    super.key,
    required this.topBannerHeight,
    required this.pageTitle,
    required this.page,
    required this.onBannerHeightChanged,
    this.userName,
  });

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  bool _loading = false;

  Future<void> _refreshInventory(BuildContext context) async {
    setState(() => _loading = true);
    try {
      await DashboardStore.instance.refresh();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory refreshed')));
      });
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top banner
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: (details) {
            widget.onBannerHeightChanged(details.delta.dy);
          },
          child: Container(
            height: widget.topBannerHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.pageTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (widget.userName != null && widget.userName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Welcome, ${widget.userName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                // Refresh button at top-right
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: _loading
                      ? const SizedBox(width: 36, height: 36, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                      : IconButton(
                          tooltip: 'Refresh inventory',
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _refreshInventory(context),
                        ),
                ),
              ],
            ),
          ),
        ),
        // Pages area (bottom right)
        Expanded(
          child: Container(color: Colors.white, child: widget.page),
        ),
      ],
    );
  }
}
