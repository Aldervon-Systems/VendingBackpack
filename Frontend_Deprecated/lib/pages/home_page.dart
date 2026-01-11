import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
// ...existing code...

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Sign-in is handled via overlays; this page is a visual placeholder.

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred SVG background using flutter_svg
        Positioned.fill(
          child: Stack(
            children: [
              SvgPicture.asset(
                'assets/vendingicon.svg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcATop),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: Colors.black.withOpacity(0.05)),
              ),
            ],
          ),
        ),
        // The actual sign-in UI is handled via app overlays/pages now.
        // Keep a minimal placeholder so this page doesn't render interactive sign-in.
        Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Please use the Sign In overlay', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    const Text('Open the menu and choose Sign In to proceed.'),
                  ],
                ),
              ),
            ),
          ),
  // If signed in, parent PagesLayout shows the dashboard; this page remains blank for now.
      ],
    );
  }
}
