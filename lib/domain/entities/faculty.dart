import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum FacultyStatus {
  available,
  busy,
  inLecture,
  away,
  meeting,
  notAvailable;

  String get label => switch (this) {
        FacultyStatus.available => 'Available',
        FacultyStatus.busy => 'Busy',
        FacultyStatus.inLecture => 'In Lecture',
        FacultyStatus.away => 'Away',
        FacultyStatus.meeting => 'In Meeting',
        FacultyStatus.notAvailable => 'Not Available',
      };

  Color get color => switch (this) {
        FacultyStatus.available => AppColors.available,
        FacultyStatus.busy => AppColors.busy,
        FacultyStatus.inLecture => AppColors.inLecture,
        FacultyStatus.away => AppColors.away,
        FacultyStatus.meeting => AppColors.meeting,
        FacultyStatus.notAvailable => AppColors.notAvailable,
      };

  IconData get icon => switch (this) {
        FacultyStatus.available => Icons.check_circle,
        FacultyStatus.busy => Icons.schedule,
        FacultyStatus.inLecture => Icons.mic,
        FacultyStatus.away => Icons.directions_walk,
        FacultyStatus.meeting => Icons.groups,
        FacultyStatus.notAvailable => Icons.cancel,
      };
}

class Faculty extends Equatable {
  final String id;
  final String name;
  final String email;
  final String department;
  final String building;
  final String cabinId;
  final FacultyStatus status;
  final String? zone;
  final String? specialization;
  final String? bio;
  final String? avatarUrl;
  final String? phoneNumber;
  final int publicationsCount;
  final double rating;
  final int consultationCount;
  final DateTime lastUpdated;
  final DateTime? expectedReturnAt;
  final DateTime? manualOverrideUntil;
  final String? activeContext;

  const Faculty({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.building,
    required this.cabinId,
    required this.status,
    this.zone,
    this.specialization,
    this.bio,
    this.avatarUrl,
    this.phoneNumber,
    this.publicationsCount = 0,
    this.rating = 0.0,
    this.consultationCount = 0,
    required this.lastUpdated,
    this.expectedReturnAt,
    this.manualOverrideUntil,
    this.activeContext,
  });

  String get initials {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  bool get isAvailable => status == FacultyStatus.available;

  bool get hasManualOverride =>
      manualOverrideUntil != null && manualOverrideUntil!.isAfter(DateTime.now());

  Faculty copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? building,
    String? cabinId,
    FacultyStatus? status,
    String? zone,
    String? specialization,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
    int? publicationsCount,
    double? rating,
    int? consultationCount,
    DateTime? lastUpdated,
    DateTime? expectedReturnAt,
    DateTime? manualOverrideUntil,
    String? activeContext,
  }) {
    return Faculty(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      building: building ?? this.building,
      cabinId: cabinId ?? this.cabinId,
      status: status ?? this.status,
      zone: zone ?? this.zone,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      publicationsCount: publicationsCount ?? this.publicationsCount,
      rating: rating ?? this.rating,
      consultationCount: consultationCount ?? this.consultationCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expectedReturnAt: expectedReturnAt ?? this.expectedReturnAt,
      manualOverrideUntil: manualOverrideUntil ?? this.manualOverrideUntil,
      activeContext: activeContext ?? this.activeContext,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        department,
        building,
        cabinId,
        status,
        zone,
        specialization,
        bio,
        avatarUrl,
        phoneNumber,
        publicationsCount,
        rating,
        consultationCount,
        lastUpdated,
        expectedReturnAt,
        manualOverrideUntil,
        activeContext,
      ];
}
