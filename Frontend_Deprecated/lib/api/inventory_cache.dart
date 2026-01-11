import 'package:flutter/foundation.dart';

/// In-memory inventory cache shared between manager and employee views.
/// Not persisted across app restarts.
class InventoryCache extends ChangeNotifier {
  InventoryCache._internal();
  static final InventoryCache instance = InventoryCache._internal();

  // machineId -> list of {sku,name,qty,cap}
  Map<String, List<Map<String, dynamic>>> _inventory = {};

  Map<String, List<Map<String, dynamic>>> get inventory => _inventory;

  bool get hasData => _inventory.isNotEmpty;

  void clearCache() {
    _inventory.clear();
    notifyListeners();
  }

  void setInventory(Map<String, List<Map<String, dynamic>>> inv) {
    // Deep-copy to avoid sharing references with callers.
    final copy = <String, List<Map<String, dynamic>>>{};
    String _norm(String s) => s.toString().trim().toLowerCase();
    inv.forEach((k, v) {
      copy[_norm(k)] = v.map((e) => Map<String, dynamic>.from(e)).toList();
    });
    _inventory = copy;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[InventoryCache] setInventory: ${_inventory.keys.length} machines');
    }
    notifyListeners();
  }

  void updateMachine(String machineId, List<Map<String, dynamic>> rows) {
    final mid = machineId.toString().trim().toLowerCase();
    _inventory[mid] = rows.map((e) => Map<String, dynamic>.from(e)).toList();
    if (kDebugMode) {
      // ignore: avoid_print
      print('[InventoryCache] updateMachine: $machineId rows=${_inventory[machineId]?.length}');
    }
    notifyListeners();
  }

  /// Fill a whole row (set qty == cap for each sku)
  void fillRow(String machineId) {
    final mid = machineId.toString().trim().toLowerCase();
    final list = _inventory[mid];
    if (list == null) return;
    for (final e in list) {
      final cap = (e['cap'] is num) ? (e['cap'] as num).toInt() : int.tryParse(e['cap']?.toString() ?? '') ?? 0;
      e['qty'] = cap;
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('[InventoryCache] fillRow: $machineId');
    }
    notifyListeners();
  }

  /// Fill a single sku row for a machine (set qty == cap for that sku)
  void fillSku(String machineId, String sku) {
    final mid = machineId.toString().trim().toLowerCase();
    final sk = sku.toString().trim().toLowerCase();
    final list = _inventory[mid];
    if (list == null) return;
    for (final e in list) {
      if ((e['sku'] ?? '').toString().trim().toLowerCase() == sk) {
        final cap = (e['cap'] is num) ? (e['cap'] as num).toInt() : int.tryParse(e['cap']?.toString() ?? '') ?? 0;
        e['qty'] = cap;
        break;
      }
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('[InventoryCache] fillSku: $machineId sku=$sku');
    }
    notifyListeners();
  }
}
