import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/auth/SessionManager.dart';
import 'modules/auth/AccessScreens.dart';
import 'modules/layout/PagesLayout.dart';
import 'modules/dashboard/BusinessMetrics.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionManager()),
        ChangeNotifierProvider(create: (_) => BusinessMetrics()),
      ],
      child: MaterialApp(
        title: 'VendingBackpack',
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
          fontFamily: 'serif',
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    if (session.isAuthenticated) {
      return const PagesLayout();
    }
    return const AccessScreens();
  }
}
