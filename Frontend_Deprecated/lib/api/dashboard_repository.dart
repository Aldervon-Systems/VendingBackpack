// lib/api/dashboard_repository.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'local_data.dart';
import 'inventory_cache.dart';

// ---------- Safe parsing ----------
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true') return 1;
    if (s == 'false') return 0;
    return int.tryParse(s) ?? (double.tryParse(s)?.toInt() ?? 0);
  }
  return 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? (int.tryParse(v)?.toDouble() ?? 0);
  return 0;
}

String _toLower(dynamic v, [String fallback = '']) =>
    (v ?? fallback).toString().toLowerCase();

DateTime? _toDate(dynamic ts) {
  if (ts == null) return null;
  if (ts is DateTime) return ts;
  if (ts is int) {
    if (ts > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(ts);
    if (ts > 1000000000) return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }
  if (ts is String) return DateTime.tryParse(ts);
  return null;
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

bool _isOnline(dynamic status) {
  final s = _toLower(status);
  if (s == 'online' || s == 'up' || s == 'active' || s == 'true') return true;
  if (s == 'offline' || s == 'down' || s == 'false') return false;
  final n = _toInt(status);
  if (n == 1) return true;
  if (n == 0) return false;
  return true; // optimistic default
}

// Stock may be List<Map> or Map<sku, {...}>
Iterable<Map<String, dynamic>> _asStock(dynamic stock) sync* {
  if (stock == null) return;
  if (stock is List) {
    for (final it in stock) {
      if (it is Map) yield Map<String, dynamic>.from(it);
    }
    return;
  }
  if (stock is Map) {
    for (final e in stock.entries) {
      final m = (e.value is Map) ? Map<String, dynamic>.from(e.value) : <String, dynamic>{'qty': e.value};
      m['sku'] = e.key.toString();
      yield m;
    }
  }
}

// ---------- Models ----------
class LowStockItem {
  final String machineId;
  final String sku;
  final int qty;
  final int capacity;
  double get pct => capacity > 0 ? qty / capacity : 0;
  bool get isCritical => pct < 0.05;
  bool get isLow => pct >= 0.05 && pct < 0.20;
  LowStockItem(this.machineId, this.sku, this.qty, this.capacity);
}

class MachineLowGroup {
  final String machineId;
  final List<LowStockItem> items;
  int get criticalCount => items.where((e) => e.isCritical).length;
  int get lowCount => items.where((e) => e.isLow).length;
  MachineLowGroup(this.machineId, this.items);
}

class DailyPoint {
  final DateTime day;
  final double amount;
  DailyPoint(this.day, this.amount);
}

class DashboardData {
  final double revenueToday;
  final double revenue7d;
  final double revenueMtd;
  final int machinesTotal;
  final int machinesOnline;
  final List<String> machinesOnlineIds;
  final int restockAlerts;
  final int restockCritical; // <5%
  final int restockLow;      // 5–20%
  final List<LowStockItem> lowStockTop; // still available if you want
  final List<MachineLowGroup> machinesNeedingRestock; // NEW: all machines
  final Map<String, List<Map<String, dynamic>>> machinesInventory; // sku list per machine
  final List<DailyPoint> last7Days;
  final bool usingSimulated;
  final int unitsSoldToday;

  DashboardData({
    required this.revenueToday,
    required this.revenue7d,
    required this.revenueMtd,
    required this.machinesTotal,
    required this.machinesOnline,
    required this.machinesOnlineIds,
    required this.restockAlerts,
    required this.restockCritical,
    required this.restockLow,
    required this.lowStockTop,
    required this.machinesNeedingRestock,
    required this.machinesInventory,
    required this.last7Days,
    required this.usingSimulated,
    required this.unitsSoldToday,
  });
}

class _Inv {
  int qty;
  int cap;
  _Inv(this.qty, this.cap);
  double get pct => cap > 0 ? qty / cap : 0;
}

// ---------- Repository ----------
class DashboardRepository {
  static Future<List<Map<String, dynamic>>> getMachines() async {
    final machines = await LocalData.machines();
    return List<Map<String, dynamic>>.from(machines);
  }
  static const int _activityWindowHours = 24;

  static Future<DashboardData> load() async {
    final machines = await LocalData.machines();
    // Fetch history and status concurrently to avoid timeouts making us miss status
    final historyF = LocalData.history();
    final statusF = LocalData.status();
    final history = await historyF;
    final statusList = await statusF;

    // Prefer authoritative inventory from backend when available
    final Map<String, dynamic> authoritative = await LocalData.inventory();

    // Online (status) - prefer backend status
    final statusOnlineIds = <String>{};
    for (final id in statusList) {
      if (id.isNotEmpty) statusOnlineIds.add(id);
    }
    // fallback: scan machine objects for local status field if backend returned none
    if (statusOnlineIds.isEmpty) {
      for (final m in machines) {
        final map = (m is Map) ? Map<String, dynamic>.from(m) : <String, dynamic>{};
        final mid = (map['id'] ?? map['machineId'] ?? '').toString();
        if (mid.isEmpty) continue;
        if (_isOnline(map['status'] ?? map['online'])) statusOnlineIds.add(mid);
      }
    }

    // If no history is available, we mark that the app is using simulated data
    bool usingSimulated = history.isEmpty || _sumRevenue(history) == 0;

    // Online (activity window)
    final activityCutoff = DateTime.now().subtract(const Duration(hours: _activityWindowHours));
    final activityOnlineIds = <String>{};
    for (final e in history) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final mid = (m['machineId'] ?? m['machine'] ?? '').toString();
      final ts  = _toDate(m['timestamp'] ?? m['time'] ?? m['ts'] ?? m['date'] ?? m['soldAt']);
      if (mid.isEmpty || ts == null) continue;
      if (!ts.isBefore(activityCutoff)) activityOnlineIds.add(mid);
    }
  // Clamp onlineIds to only those present in the actual machine list
  final machineIds = machines.map((m) => (m is Map ? (m['id'] ?? m['machineId'] ?? '').toString() : m.toString())).toSet();
  final onlineIds = {...statusOnlineIds, ...activityOnlineIds}..removeWhere((id) => !machineIds.contains(id));
  final machinesOnline = onlineIds.length;

    // Build inventory (either from authoritative backend inventory, or from local assets/history)
    final inv = <String, Map<String, _Inv>>{};
    final machinesInventory = <String, List<Map<String, dynamic>>>{};

    if (authoritative.isNotEmpty) {
      // Convert authoritative map into internal structures
      String _norm(String s) => s.toString().trim().toLowerCase();
      authoritative.forEach((rawMid, v) {
        final mid = _norm(rawMid);
        machinesInventory[mid] = <Map<String, dynamic>>[];
        if (v is List) {
          for (final it in v) {
            if (it is Map) {
              final m = Map<String, dynamic>.from(it);
              final sku = (m['sku'] ?? m['name'] ?? '').toString();
              final qty = _toInt(m['qty'] ?? m['quantity'] ?? 0);
              final cap = max(_toInt(m['cap'] ?? m['capacity'] ?? 0), max(qty, 1));
              machinesInventory[mid]!.add({'sku': sku, 'name': m['name'] ?? sku, 'qty': qty, 'cap': cap});
              inv[mid] = inv[mid] ?? <String, _Inv>{};
              inv[mid]![sku] = _Inv(qty, cap);
            }
          }
        } else if (v is Map) {
          // Map of sku -> entry
          v.forEach((skuKey, entry) {
            final sku = skuKey.toString();
            if (entry is Map) {
              final m = Map<String, dynamic>.from(entry);
              final qty = _toInt(m['qty'] ?? m['quantity'] ?? 0);
              final cap = max(_toInt(m['cap'] ?? m['capacity'] ?? 0), max(qty, 1));
              machinesInventory[mid]!.add({'sku': sku, 'name': m['name'] ?? sku, 'qty': qty, 'cap': cap});
              inv[mid] = inv[mid] ?? <String, _Inv>{};
              inv[mid]![sku] = _Inv(qty, cap);
            }
          });
        }
      });
    } else {
      // Build from local machines and any embedded stock fields (legacy)
      for (final m in machines) {
        final map = (m is Map) ? Map<String, dynamic>.from(m) : <String, dynamic>{};
        final mid = (map['id'] ?? map['machineId'] ?? '').toString();
        if (mid.isEmpty) continue;
        final slots = inv[mid] = inv[mid] ?? <String, _Inv>{};

        for (final s in _asStock(map['stock'] ?? map['inventory'] ?? map['slots'])) {
          final sku = (s['sku'] ?? s['name'] ?? '').toString();
          if (sku.isEmpty) continue;
          final qty = _toInt(s['qty'] ?? s['quantity'] ?? s['current']);
          final cap = max(_toInt(s['capacity'] ?? s['cap'] ?? s['max']), max(qty, 1));
          slots[sku] = _Inv(qty, cap);
        }
      }
      // machinesInventory will be built below via randomization logic
    }

    // Apply history to inventory
    for (final e in history) {
      final map = (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{};
      final mid = (map['machineId'] ?? map['machine'] ?? '').toString();
      final sku = (map['sku'] ?? map['product'] ?? '').toString();
      if (mid.isEmpty || sku.isEmpty) continue;
      final q = max(1, _toInt(map['qty'] ?? map['quantity'] ?? 1));
      final mSlots = inv[mid] ??= <String, _Inv>{};
      final entry  = mSlots[sku] ??= _Inv(0, q);
      entry.qty = max(0, entry.qty - q);
    }

    // Low stock items & grouping
    final lowItems = <LowStockItem>[];
    final byMachine = <String, List<LowStockItem>>{};
    int low = 0, critical = 0;
    int restockWarnings = 0;

    // Count yellow/red icons by iterating actual machinesInventory
    machinesInventory.forEach((mid, items) {
      for (final item in items) {
        final qty = (item['qty'] is num) ? (item['qty'] as num).toInt() : 0;
        if (qty == 0) {
          restockWarnings++;
        } else if (qty < 5) {
          restockWarnings++;
        }
      }
    });

    // Low stock grouping (unchanged)
    inv.forEach((mid, slots) {
      slots.forEach((sku, entry) {
        final item = LowStockItem(mid, sku, entry.qty, entry.cap);
        if (item.pct < 0.20) {
          lowItems.add(item);
          (byMachine[mid] ??= <LowStockItem>[]).add(item);
          if (item.isCritical) critical++; else low++;
        }
      });
    });

    // Sort items (critical first, then lowest %)
    lowItems.sort((a, b) {
      final ac = a.isCritical ? 0 : 1;
      final bc = b.isCritical ? 0 : 1;
      if (ac != bc) return ac - bc;
      return a.pct.compareTo(b.pct);
    });

    // Build machine groups (no max, show all)
    final groups = <MachineLowGroup>[];
    byMachine.forEach((mid, items) {
      items.sort((a, b) {
        final ac = a.isCritical ? 0 : 1;
        final bc = b.isCritical ? 0 : 1;
        if (ac != bc) return ac - bc;
        return a.pct.compareTo(b.pct);
      });
      groups.add(MachineLowGroup(mid, items));
    });
    // Sort machines by severity (most critical items first), then by count
    groups.sort((a, b) {
      if (a.criticalCount != b.criticalCount) return b.criticalCount - a.criticalCount;
      if (a.lowCount != b.lowCount) return b.lowCount - a.lowCount;
      return a.machineId.compareTo(b.machineId);
    });

    final alerts = lowItems.length;
    final worst5 = lowItems.take(5).toList(); // still available if you want it

    // Master SKU list (fixed Coke-focused SKUs + display names)
    final Map<String, String> masterSkus = {
      'item_1': 'Coca‑Cola Classic',
      'item_2': 'Coca‑Cola Zero',
      'item_3': 'Sprite',
      'item_4': 'Diet Coke',
      'item_5': 'Coca‑Cola Cherry',
      'item_6': 'Fanta Orange',
      'item_7': 'Minute Maid',
      'item_8': 'Dasani Water',
    };
  // Per-SKU prices used to derive revenue from randomized initial stock (sold = cap - qty)
    final Map<String, double> skuPrices = {
      'item_1': 1.50,
      'item_2': 1.50,
      'item_3': 1.25,
      'item_4': 1.50,
      'item_5': 1.75,
      'item_6': 1.25,
      'item_7': 2.00,
      'item_8': 1.00,
    };
    const int defaultCapacity = 20;
    final rnd = Random();

    double extraRevenueFromInventory = 0.0;

    // Build full machinesInventory map if authoritative inventory wasn't provided.
    String _norm(String s) => s.toString().trim().toLowerCase();
    // Ensure every machine has an entry even if inv is empty
    for (final m in machines) {
      final raw = m is String ? m : (m is Map ? (m['id'] ?? m['machineId'] ?? '').toString() : m.toString());
      final mid = _norm(raw);
      if (mid.isEmpty) continue;
      machinesInventory[mid] = <Map<String, dynamic>>[];
    }
    // Fill quantities from computed inv map; missing SKUs get qty 0 and default cap
    machinesInventory.forEach((mid, list) {
      final slots = inv[mid] ?? <String, _Inv>{};
      for (final sku in masterSkus.keys) {
        final entry = slots[sku];
  // Randomize initial stock when missing; otherwise keep computed qty
  // If an existing cap is tiny (<=1) treat it as missing and use defaultCapacity
  var cap = entry?.cap ?? defaultCapacity;
  if (cap <= 1) cap = defaultCapacity;
        final qty = entry?.qty ?? rnd.nextInt(cap + 1);
        list.add({'sku': sku, 'name': masterSkus[sku] ?? sku, 'qty': qty, 'cap': cap});
        // Sold units (assume cap - qty were sold today) contribute to today's revenue
        final sold = (cap - qty) > 0 ? (cap - qty) : 0;
        final price = skuPrices[sku] ?? 0.0;
        extraRevenueFromInventory += sold * price;
      }
    });

    // We'll add extraRevenueFromInventory to revenueToday below

    // Revenue windows + daily points
    final now = DateTime.now();
    DateTime sod(DateTime d) => DateTime(d.year, d.month, d.day);
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

    final today = sod(now);
    final sevenDaysAgo = sod(now.subtract(const Duration(days: 6)));
    final monthStart = DateTime(now.year, now.month, 1);

    double rToday = 0, r7d = 0, rMtd = 0;
    final perDay = <String, double>{};
  int unitsSoldToday = 0;

    for (final e in history) {
      final map = (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{};

      final ts = _toDate(map['timestamp'] ?? map['time'] ?? map['ts'] ?? map['date'] ?? map['soldAt']);
      if (ts == null) continue;

      double amt = _toDouble(map['amount'] ?? map['total'] ?? map['revenue']);
      if (amt == 0) {
        final price = _toDouble(map['price']);
        final qty   = max(1, _toInt(map['qty'] ?? map['quantity']));
        amt = price * qty;
      }

      if (ts.isAfter(today) || sameDay(ts, today)) rToday += amt;
      if (ts.isAfter(today) || sameDay(ts, today)) {
        unitsSoldToday += max(1, _toInt(map['qty'] ?? map['quantity'] ?? 1));
      }
      if ((ts.isAfter(sevenDaysAgo) || sameDay(ts, sevenDaysAgo)) &&
          ts.isBefore(today.add(const Duration(days: 1)))) r7d += amt;
      if (ts.isAfter(monthStart) || sameDay(ts, monthStart)) rMtd += amt;

      final key = _ymd(sod(ts));
      perDay[key] = (perDay[key] ?? 0) + amt;
    }

    final points = <DailyPoint>[];
    for (int i = 6; i >= 0; i--) {
      final d = sod(now.subtract(Duration(days: i)));
      points.add(DailyPoint(d, perDay[_ymd(d)] ?? 0));
    }
    // Add revenue derived from initial randomized inventory (assume sold earlier today)
    if (extraRevenueFromInventory > 0) {
      rToday += extraRevenueFromInventory;
      rMtd += extraRevenueFromInventory;
      // Add units implied by randomized inventory
      machinesInventory.forEach((mid, list) {
        for (final e in list) {
          final cap = (e['cap'] is num) ? (e['cap'] as num).toInt() : int.tryParse(e['cap']?.toString() ?? '') ?? 0;
          final qty = (e['qty'] is num) ? (e['qty'] as num).toInt() : int.tryParse(e['qty']?.toString() ?? '') ?? 0;
          final sold = (cap - qty) > 0 ? (cap - qty) : 0;
          unitsSoldToday += sold;
        }
      });
    }

  // Publish inventory to shared cache so manager and employee views stay in sync.
  if (kDebugMode) {
    // ignore: avoid_print
    print('[DashboardRepository] Publishing inventory to cache: ${machinesInventory.keys.length} machines (authoritative: ${authoritative.isNotEmpty})');
  }
  // Only overwrite the shared cache when we received authoritative data from
  // the backend. If no authoritative inventory was available, avoid stomping
  // the cache so optimistic UI updates (e.g. after a fill) are not immediately
  // reverted by simulated fallback inventory. If the cache is empty, populate
  // it so initial load still works.
  if (authoritative.isNotEmpty) {
    InventoryCache.instance.setInventory(machinesInventory);
  } else {
    if (!InventoryCache.instance.hasData) {
      InventoryCache.instance.setInventory(machinesInventory);
    } else {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[DashboardRepository] Skipping cache overwrite: no authoritative inventory and cache already populated');
      }
    }
  }

    return DashboardData(
      revenueToday: rToday,
      revenue7d: r7d,
      revenueMtd: rMtd,
  machinesTotal: machines.length,
  machinesOnline: machinesOnline,
  machinesOnlineIds: onlineIds.toList(),
  restockAlerts: restockWarnings,
      restockCritical: critical,
      restockLow: low,
      lowStockTop: worst5,
      machinesNeedingRestock: groups,
      machinesInventory: machinesInventory,
      last7Days: points,
      usingSimulated: usingSimulated,
      unitsSoldToday: unitsSoldToday,
    );
  }

  static double _sumRevenue(List<dynamic> history) {
    double sum = 0;
    for (final e in history) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      double amt = _toDouble(m['amount'] ?? m['total'] ?? m['revenue']);
      if (amt == 0) {
        final price = _toDouble(m['price']);
        final qty = max(1, _toInt(m['qty'] ?? m['quantity']));
        amt = price * qty;
      }
      sum += amt;
    }
    return sum;
  }
}
