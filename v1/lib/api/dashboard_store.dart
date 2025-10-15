  // Expose online machine IDs from dashboard data
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dashboard_repository.dart';
import 'local_data.dart';

// Removed invalid top-level getter for onlineIds


class DashboardSnapshot {
  List<String> get onlineIds => dashboard.machinesOnlineIds;
  final DashboardData dashboard;
  final List<dynamic> machines;
  final List<dynamic> locations;

  DashboardSnapshot({
    required this.dashboard,
    required this.machines,
    required this.locations,
  });
}

class DashboardStore extends ChangeNotifier {
  DashboardStore._();
  static final DashboardStore instance = DashboardStore._();

  DashboardSnapshot? _snapshot;
  bool _loading = false;
  Object? _error;
  Future<void>? _pending;

  void clearSnapshot() {
    _snapshot = null;
    _error = null;
    notifyListeners();
  }

  DashboardSnapshot? get snapshot => _snapshot;
  DashboardData? get dashboard => _snapshot?.dashboard;
  List<dynamic> get machines => List<dynamic>.from(_snapshot?.machines ?? const []);
  List<dynamic> get locations => List<dynamic>.from(_snapshot?.locations ?? const []);
  bool get isLoading => _loading;
  Object? get error => _error;
  bool get hasData => _snapshot != null;

  Future<void> ensureLoaded() async {
    if (_snapshot != null) {
      if (_pending != null) {
        await _pending;
      }
      return;
    }
    await refresh();
  }

  Future<DashboardSnapshot> refresh({bool silent = false}) {
    if (_pending != null) {
      return _pending!.then((_) => _snapshot!);
    }

    final completer = Completer<DashboardSnapshot>();
    _pending = completer.future;

    if (!silent) {
      _loading = true;
      notifyListeners();
    }

    () async {
      try {
        if (kDebugMode) {
          print('[DashboardStore] Starting refresh (silent=$silent)');
        }
        final results = await Future.wait([
          DashboardRepository.load(),
          LocalData.machines(),
          LocalData.locations(),
        ], eagerError: true);

        final dash = results[0] as DashboardData;
        final machinesRaw = results[1] as List<dynamic>;
        final locationsRaw = results[2] as List<dynamic>;

        _snapshot = DashboardSnapshot(
          dashboard: dash,
          machines: List<dynamic>.from(machinesRaw.map((e) => _cloneMapIfNeeded(e))),
          locations: List<dynamic>.from(locationsRaw.map((e) => _cloneMapIfNeeded(e))),
        );
        _error = null;
        _loading = false;
        if (kDebugMode) {
          print('[DashboardStore] Refresh complete, notifying listeners');
        }
        notifyListeners();
        completer.complete(_snapshot!);
      } catch (e, st) {
        _error = e;
        _loading = false;
        if (kDebugMode) {
          debugPrint('[DashboardStore] refresh failed: $e\n$st');
        }
        notifyListeners();
        completer.completeError(e, st);
      } finally {
        _pending = null;
      }
    }();

    return completer.future;
  }

  static dynamic _cloneMapIfNeeded(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value.map((key, val) => MapEntry(key.toString(), val)));
    }
    return value;
  }
}
