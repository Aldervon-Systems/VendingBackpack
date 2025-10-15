import 'dart:math';
import 'package:flutter/material.dart';
import 'api/employees_repository.dart';

class UserProfile extends ChangeNotifier {
  String? employeeId;
  bool isManager = false;
  Color? color;

  Future<void> signIn({required bool manager, String? id}) async {
    isManager = manager;
    if (!manager && id != null) {
      employeeId = id;
      await _assignEmployeeColorAndSave(id);
    }
    notifyListeners();
  }

  Future<void> _assignEmployeeColorAndSave(String id) async {
    final employees = await EmployeesRepository.loadEmployees();
    // Find unused color
    final usedColors = employees.map((e) => e.color.value).toSet();
    final palette = [
      4294901760, // Red
      4278190335, // Blue
      4278255360, // Green
      4294967040, // Yellow
      4294967295, // White
      4280391411, // Orange
      4283215696, // Purple
      4280391411, // Orange
      4283788079, // Cyan
      4290822336, // Lime
    ];
    int assigned = palette.firstWhere((c) => !usedColors.contains(c), orElse: () => Random().nextInt(0xFFFFFFFF));
    color = Color(assigned);
    employees.add(Employee(id: id, name: id, color: color!));
    await EmployeesRepository.saveEmployees(employees);
  }
}
