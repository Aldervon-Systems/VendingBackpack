// lib/api/employees_store_io.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'employees_store.dart';

class _IoEmployeesStore implements EmployeesStore {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/employees.json');
  }

  @override
  Future<String?> read() async {
    final f = await _file();
    if (await f.exists()) return f.readAsString();
    return null;
  }

  @override
  Future<void> write(String json) async {
    final f = await _file();
    await f.writeAsString(json);
  }

  @override
  Future<String?> export(String prettyJson, {String fileName = 'employees.json'}) async {
    // For simplicity, we export to the same support file.
    final f = await _file();
    await f.writeAsString(prettyJson);
    return 'Saved to ${f.path}';
  }
}

EmployeesStore createEmployeesStore() => _IoEmployeesStore();
