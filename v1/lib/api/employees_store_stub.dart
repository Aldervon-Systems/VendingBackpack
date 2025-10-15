// lib/api/employees_store_stub.dart
import 'employees_store.dart';

class _StubEmployeesStore implements EmployeesStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String json) async {}

  @override
  Future<String?> export(String prettyJson, {String fileName = 'employees.json'}) async => null;
}

EmployeesStore createEmployeesStore() => _StubEmployeesStore();
