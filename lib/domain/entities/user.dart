import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum UserRole { student, admin, faculty }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.faculty => 'Faculty',
        UserRole.student => 'Student',
      };

  Color get color => switch (this) {
        UserRole.admin => AppColors.error,
        UserRole.faculty => AppColors.primary,
        UserRole.student => AppColors.info,
      };
}

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final String? studentCode;
  final String? department;
  final String? phoneNumber;
  final int? yearOfStudy;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.studentCode,
    this.department,
    this.phoneNumber,
    this.yearOfStudy,
    required this.createdAt,
    this.lastLoginAt,
  });

  String get initials {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String get yearLabel => yearOfStudy != null ? 'Year $yearOfStudy' : '';

  User copyWith({
    String? id, String? name, String? email, String? avatarUrl,
    UserRole? role, String? studentCode, String? department,
    String? phoneNumber, int? yearOfStudy,
    DateTime? createdAt, DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      studentCode: studentCode ?? this.studentCode,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatarUrl, role, studentCode,
      department, phoneNumber, yearOfStudy, createdAt, lastLoginAt];
}
