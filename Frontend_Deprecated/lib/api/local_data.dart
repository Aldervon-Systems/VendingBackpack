
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'inventory_cache.dart';

// Returns the correct backend base URL for the current platform
String localDataBaseUrl() {
  // Use LAN IP for network access from devices
  return 'http://10.0.0.19:5050';
}

class LocalData {
  static const _listKeys = [
    'items', 'data', 'results', 'locations', 'machines', 'records', 'list',
  ];

  static Future<List<dynamic>> machines() async {
    final raw = await _loadListSmart('src/data/machines.json', fallbackName: 'machines.json');
    if (raw.isNotEmpty && raw.first is String) {
      return raw.map((e) => {'id': e.toString(), 'name': e.toString()}).toList();
    }
    return raw;
  }
  static Future<List<dynamic>> locations() async {
    final raw = await _loadListSmart('src/data/locations.json', fallbackName: 'locations.json');
    if (raw.isNotEmpty && raw.first is String) {
      return raw.map((e) => {'id': e.toString(), 'name': e.toString()}).toList();
    }
    return raw;
  }
  static Future<List<dynamic>> history() async {
    final raw = await _loadListSmart('src/data/history.json', fallbackName: 'history.json');
    if (raw.isNotEmpty && raw.first is String) {
      return raw.map((e) => {'id': e.toString(), 'name': e.toString()}).toList();
    }
    return raw;
  }

  /// Fetch status from backend: returns list of online machine ids, or [] on miss.
  static Future<List<String>> status() async {
    // Try both loopback addresses because some browser contexts treat
    // 'localhost' and '127.0.0.1' differently.
    final candidates = ['127.0.0.1', 'localhost'];
    for (final host in candidates) {
      try {
        final uri = Uri.parse('http://$host:5050/status');
        _dbg('Status: trying $uri');
        final resp = await http.get(uri).timeout(const Duration(milliseconds: 3000));
        _dbg('Status ($host): HTTP ${resp.statusCode}');
        _dbg('Status ($host): body: ${resp.body}');
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map && decoded['online'] is List) {
            final out = (decoded['online'] as List).map((e) => e.toString()).toList();
            _dbg('Status parsed ($host): ${out.length} online');
            return out;
          }
        }
      } catch (e) {
        _dbg('Status ($host) exception: $e');
      }
    }
    return const <String>[];
  }

  /// Fetch authoritative inventory from backend (/inventory) which returns a map.
  static Future<Map<String, dynamic>> inventory() async {
    try {
      final uri = Uri.parse(localDataBaseUrl() + '/inventory');
      final resp = await http.get(uri).timeout(const Duration(milliseconds: 1000));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  /// Fetch weekly daily stats from backend (/daily_stats)
  static Future<List<dynamic>> weeklyStats() async {
    // Try several host candidates because different runtimes (web, emulator,
    // physical device) may need different host/IPs to reach the development server.
    final candidates = [
      '127.0.0.1',
      'localhost',
    ];
    // Also include the configured LAN address if present in localDataBaseUrl()
    try {
      final configured = Uri.parse(localDataBaseUrl()).host;
      if (configured.isNotEmpty && !candidates.contains(configured)) candidates.add(configured);
    } catch (_) {}

    for (final host in candidates) {
      try {
        final uri = Uri.parse('http://$host:5050/daily_stats');
        final resp = await http.get(uri).timeout(const Duration(milliseconds: 1500));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) return decoded;
        }
      } catch (_) {}
    }
    return const [];
  }


  /// POST a fill action to the backend. Accepts machineId and either sku or action='row'.
  static Future<bool> postFill(String machineId, {String? sku, String? action}) async {
    try {
      final uri = Uri.parse(localDataBaseUrl() + '/inventory/fill');
      final body = <String, dynamic>{'machineId': machineId};
      if (sku != null) body['sku'] = sku;
      if (action != null) body['action'] = action;
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(milliseconds: 1500));
      if (resp.statusCode == 200) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map && decoded['inventory'] != null) {
            final inv = decoded['inventory'];
            if (inv is Map) {
              final machinesRaw = inv['machines'] ?? inv;
              if (machinesRaw is Map) {
                final out = <String, List<Map<String, dynamic>>>{};
                machinesRaw.forEach((k, v) {
                  final mid = k.toString().trim().toLowerCase();
                  if (v is List) {
                    out[mid] = List<Map<String, dynamic>>.from(v.map((e) => Map<String, dynamic>.from(e)));
                  } else if (v is Map) {
                    final list = <Map<String, dynamic>>[];
                    v.forEach((sku, entry) {
                      if (entry is Map) {
                        final m = Map<String, dynamic>.from(entry);
                        m['sku'] = sku.toString();
                        list.add(m);
                      } else {
                        list.add({'sku': sku.toString(), 'qty': entry});
                      }
                    });
                    out[mid] = list;
                  }
                });
                try {
                  InventoryCache.instance.setInventory(out);
                } catch (_) {}
              }
            }
          }
        } catch (_) {}
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<List<dynamic>> _loadListSmart(String primaryPath, {required String fallbackName}) async {
    final primary = await _tryLoadList(primaryPath);
    if (primary.isNotEmpty) {
      _dbg('OK: "$primaryPath" -> ${primary.length} rows'); _dbgSample(primary);
      return primary;
    }
    _dbg('MISS: "$primaryPath". Searching AssetManifest.json for "$fallbackName"...');

    final match = await _findAssetByFileName(fallbackName);
    if (match != null) {
      final discovered = await _tryLoadList(match);
      if (discovered.isNotEmpty) {
        _dbg('OK via manifest: "$match" -> ${discovered.length} rows'); _dbgSample(discovered);
        return discovered;
      }
      _dbg('Found "$match" in manifest, but failed to load/parse.');
    } else {
      _dbg('No asset ends with "$fallbackName" in AssetManifest.json.');
    }
    return const [];
  }

  /// Loads JSON from [path] and returns a LIST of rows.
  /// NEW: If the top-level is a MAP like { "id":[lat,lng], ... }, normalize it into
  /// [{id,name,lat,lng}, ...] so the repo can consume it.
  static Future<List<dynamic>> _tryLoadList(String path) async {
    try {
      // Only fetch from backend, do not fall back to local assets
      final uri = Uri.parse(localDataBaseUrl() + '/' + (path.endsWith('machines.json') ? 'machines' : path.endsWith('locations.json') ? 'locations' : path.endsWith('inventory.json') ? 'inventory' : 'history'));
      final resp = await http.get(uri).timeout(const Duration(milliseconds: 500));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          // Try to normalize tuple-dictionary {id:[lat,lng], ...}
          final tupleList = _normalizeTupleDict(decoded);
          if (tupleList != null) return tupleList;

          // Try boxed lists (items/data/results/etc.)
          for (final key in _listKeys) {
            final v = decoded[key];
            if (v is List) return List<dynamic>.from(v);
          }

          // Fall back to returning a single-map list (legacy behavior)
          return [decoded];
        }
      }
      // If not found or error, return empty list
      return const <dynamic>[];
    } catch (e) {
      _dbg('ERROR loading "$path": $e');
      return const <dynamic>[];
    }
  }

  /// Detects { "id": [lat, lng], ... } and returns a normalized list of maps.
  static List<dynamic>? _normalizeTupleDict(Map decoded) {
    // Peek a few entries to see if values look like [num, num]
    final entries = decoded.entries.toList();
    if (entries.isEmpty) return null;

    int tupleish = 0;
    for (final e in entries.take(10)) {
      final v = e.value;
      if (v is List && v.length >= 2 && v[0] is num && v[1] is num) tupleish++;
    }
    if (tupleish == 0) return null; // not this shape

    // Normalize all entries that match the pattern.
    final out = <Map<String, dynamic>>[];
    for (final e in entries) {
      final v = e.value;
      if (v is List && v.length >= 2 && v[0] is num && v[1] is num) {
        final a = (v[0] as num).toDouble();
        final b = (v[1] as num).toDouble();

        // Heuristic for order:
        // If a ∈ [-90,90] and b ∈ [-180,180] -> [lat,lng] (your sample).
        // Otherwise, swap.
        final bool looksLatLng = a.abs() <= 90 && b.abs() <= 180;
        final lat = looksLatLng ? a : b;
        final lng = looksLatLng ? b : a;

        out.add({
          'id': e.key.toString(),
          'name': e.key.toString(),
          'lat': lat,
          'lng': lng,
        });
      }
    }
    return out.isEmpty ? null : out;
  }

  static Future<String?> _findAssetByFileName(String fileName) async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestJson);
      Iterable<String> assets = const <String>[];
      if (manifest is Map) {
        assets = manifest.keys.cast<String>();
      } else if (manifest is List) {
        assets = manifest.cast<String>();
      }
      for (final a in assets) {
        if (a.endsWith('/$fileName') || a == fileName) return a;
      }
      return null;
    } catch (e) {
      _dbg('ERROR reading AssetManifest.json: $e');
      return null;
    }
  }

  static void _dbg(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[LocalData] $msg');
    }
  }

  static void _dbgSample(List<dynamic> rows) {
    if (!kDebugMode) return;
    final take = rows.take(3).toList();
    // ignore: avoid_print
    print('[LocalData] sample(<=3): ${take.map((e) => e.runtimeType).toList()}');
    for (var i = 0; i < take.length; i++) {
      // ignore: avoid_print
      print('[LocalData] row[$i]: ${take[i]}');
    }
  }
}
