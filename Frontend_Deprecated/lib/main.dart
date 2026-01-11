import 'dart:ui';
import 'package:flutter/material.dart';

import 'widgets/pages_layout.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          surface: Colors.white,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.black,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontFamily: 'serif',
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(color: Colors.black, fontFamily: 'serif'),
        ),
        dividerColor: Colors.black12,
        iconTheme: const IconThemeData(color: Colors.black),
        useMaterial3: true,
      ),
      home: const PagesLayout(),
    );
  }
}

void main() {
  runApp(const MyApp());
}
