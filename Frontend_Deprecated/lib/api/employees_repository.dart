// lib/api/employees_repository.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'employees_store.dart';
// rootBundle import removed: employees are derived from UsersStub when no store exists.
import 'users_stub.dart';

@immutable
class Employee {
  final String id;
  final String name;
  final Color color;

  const Employee({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
      };

  static Employee fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
    );
  }
}

class EmployeesRepository {
  static final _store = EmployeesStore.instance();

  /// Loads employees from storage, or seeds defaults if empty.
  static Future<List<Employee>> loadEmployees({String assetPath = 'src/data/employees.json'}) async {
    final jsonStr = await _store.read();
    if (jsonStr == null) {
      // No stored employees: derive employees from the login user list (UsersStub)
      // Convert any users with role == 'employee' into Employee objects.
      try {
        final users = UsersStub.users;
        final emps = <Employee>[];
        for (final u in users) {
          try {
            if (u['role'] == 'employee') {
              final id = (u['id'] ?? u['email'] ?? u['name']).toString();
              final name = (u['name'] ?? id).toString();
              // Use a deterministic color derived from the hashcode if not present
              final colorVal = u.containsKey('color') ? (u['color'] as int) : (0xFF000000 | id.hashCode & 0x00FFFFFF);
              emps.add(Employee(id: id, name: name, color: Color(colorVal)));
            }
          } catch (_) {}
        }
        if (emps.isNotEmpty) {
          await saveEmployees(emps);
          return emps;
        }
      } catch (_) {}
      return [];
    }
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.map((e) => Employee.fromJson(e)).toList();
  }

  static Future<void> saveEmployees(List<Employee> employees) async {
    final jsonStr = jsonEncode(employees.map((e) => e.toJson()).toList());
    await _store.write(jsonStr);
  }
}
