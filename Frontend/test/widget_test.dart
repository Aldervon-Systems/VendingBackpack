import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vending_backpack_v2/main.dart';
import 'package:vending_backpack_v2/core/services/SurfaceControl.dart';
import 'package:vending_backpack_v2/modules/auth/SessionManager.dart';

void main() {
  testWidgets('App boots to auth screen when no session exists', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    SurfaceControlService.disableForTests = true;
    SessionManager.disableCliSessionImportForTests = true;

    await tester.pumpWidget(const MyApp());
    for (var i = 0; i < 8 && find.text('Sign In').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
