// lib/api/employees_store.dart
// Platform-agnostic facade with conditional imports.

import 'employees_store_stub.dart'
  if (dart.library.html) 'employees_store_web.dart'
  if (dart.library.io) 'employees_store_io.dart';

abstract class EmployeesStore {
  /// Return JSON string or null if not found.
  Future<String?> read();
  /// Persist JSON string (overwrites).
  Future<void> write(String json);

  /// Export a pretty JSON for user to keep (web: download; io: write a file and return path).
  /// Returns a human-friendly message (e.g., "Saved to ...") if applicable.
  Future<String?> export(String prettyJson, {String fileName = 'employees.json'});

  static EmployeesStore instance() => createEmployeesStore();
}
