import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'modules/routes/RoutePlanner.dart';
import 'modules/auth/SessionManager.dart';
import 'modules/auth/AccessScreens.dart';
import 'modules/layout/PagesLayout.dart';
import 'modules/dashboard/BusinessMetrics.dart';
import 'core/styles/AppStyle.dart';

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
        ChangeNotifierProvider(create: (_) => RoutePlanner()),
      ],
      child: MaterialApp(
        title: 'VendingBackpack v3.0.0 (MT)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.foundation,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.actionAccent,
            surface: AppColors.surface,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
              .copyWith(
                displayLarge: AppStyle.metric(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                headlineMedium: AppStyle.metric(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                bodyMedium: AppStyle.label(
                  fontSize: 14,
                  color: AppColors.dataPrimary,
                ),
                bodySmall: AppStyle.label(fontSize: 12),
              ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.dataPrimary,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.dataPrimary,
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.border,
            thickness: 1,
            space: 1,
          ),
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
    if (session.isRestoring) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.border,
          ),
        ),
      );
    }
    if (session.isAuthenticated) {
      return const PagesLayout();
    }
    return const AccessScreens();
  }
}
