enum UserRole {
  student('student'),
  faculty('faculty'),
  admin('admin');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.student,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.authId,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String authId;
}
