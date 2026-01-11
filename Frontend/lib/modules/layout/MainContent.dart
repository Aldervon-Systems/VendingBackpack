import 'package:flutter/material.dart';

class MainContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: (details) => onBannerHeightChanged(details.delta.dy),
          child: Container(
            height: topBannerHeight,
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
                    pageTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                if (userName != null && userName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Welcome, $userName',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(color: Colors.white, child: page),
        ),
      ],
    );
  }
}
