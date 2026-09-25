import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.authId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromValue(
        map['role'] as String? ?? UserRole.student.value,
      ),
      authId: map['auth_id'] as String? ?? '',
    );
  }

  factory UserModel.fromAuthUser(
    User user, {
    String? fallbackName,
    UserRole? fallbackRole,
  }) {
    final metadataRole = user.userMetadata?['role'] as String?;
    final metadataName = user.userMetadata?['full_name'] as String?;

    return UserModel(
      id: user.id,
      name: metadataName ?? fallbackName ?? '',
      email: user.email ?? '',
      role: metadataRole != null
          ? UserRole.fromValue(metadataRole)
          : (fallbackRole ?? UserRole.student),
      authId: user.id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'full_name': name,
      'email': email,
      'role': role.value,
      'auth_id': authId,
    };
  }
}
