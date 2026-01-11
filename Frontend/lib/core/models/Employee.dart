import 'dart:ui';

class Employee {
  final String id;
  final String name;
  final Color color;

  Employee({required this.id, required this.name, required this.color});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: Color(json['color'] ?? 0xFF000000),
    );
  }
}
