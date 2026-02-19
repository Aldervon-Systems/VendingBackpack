class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? organizationId;

  User({required this.id, required this.name, required this.email, required this.role, this.organizationId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      organizationId: json['organization_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'organization_id': organizationId,
    };
  }
}
