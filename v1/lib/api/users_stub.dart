// Lightweight user store used by UI for sign-in/signup when no auth backend is available.
class UsersStub {
  static final List<Map<String, dynamic>> users = [
    {
      'email': 'Simon.swartout@gmail.com',
      'name': 'Simon Swartout',
      'password': 'test123',
      'role': 'manager',
      'id': null,
    },
    {
      'email': 'amanda.jones@example.com',
      'name': 'Amanda Jones',
      'password': 'employee123',
      'role': 'employee',
      'id': 'amanda_jones',
    },
  ];
}
