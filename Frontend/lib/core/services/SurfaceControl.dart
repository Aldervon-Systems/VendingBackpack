import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum SurfaceLaunchTarget {
  authLogin,
  authRegister,
  dashboard,
  routes,
  warehouse,
  settings,
}

class SurfaceControlService {
  static bool disableForTests = false;

  static Future<SurfaceLaunchTarget?> claimTarget() async {
    if (disableForTests) return null;
    if (kIsWeb) return null;
    try {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) return null;
      final file = File('$home/.vending-backpack/surface-control.json');
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      await file.delete();
      final payload = jsonDecode(raw);
      if (payload is! Map<String, dynamic>) return null;
      return _parseTarget(payload['target']?.toString());
    } catch (_) {
      return null;
    }
  }

  static SurfaceLaunchTarget? _parseTarget(String? value) {
    switch (value) {
      case 'auth-login':
        return SurfaceLaunchTarget.authLogin;
      case 'auth-register':
        return SurfaceLaunchTarget.authRegister;
      case 'dashboard':
        return SurfaceLaunchTarget.dashboard;
      case 'routes':
        return SurfaceLaunchTarget.routes;
      case 'warehouse':
        return SurfaceLaunchTarget.warehouse;
      case 'settings':
        return SurfaceLaunchTarget.settings;
      default:
        return null;
    }
  }
}
