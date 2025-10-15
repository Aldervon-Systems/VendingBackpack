// IO implementation using a file in application documents directory
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String> _filePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/app_storage.json';
}

Future<Map<String, dynamic>> _readAll() async {
  try {
    final p = await _filePath();
    final f = File(p);
    if (!await f.exists()) return {};
    final raw = await f.readAsString();
    if (raw.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  } catch (_) {
    return {};
  }
}

Future<void> _writeAll(Map<String, dynamic> m) async {
  final p = await _filePath();
  final f = File(p);
  await f.writeAsString(jsonEncode(m));
}

Future<void> setItem(String key, String value) async {
  final m = await _readAll();
  m[key] = value;
  await _writeAll(m);
}

Future<String?> getItem(String key) async {
  final m = await _readAll();
  return m[key]?.toString();
}

Future<void> removeItem(String key) async {
  final m = await _readAll();
  m.remove(key);
  await _writeAll(m);
}

Future<void> openUrl(String url) async {
  // No browser on IO; just print or you could use url_launcher package.
  debugPrint('Open URL: $url');
}
