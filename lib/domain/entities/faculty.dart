import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum FacultyStatus {
  available,
  busy,
  inLecture,
  away,
  meeting,
  notAvailable,
  onHoliday,
  custom; // faculty-defined custom status text

  String get label => switch (this) {
        FacultyStatus.available    => 'Available',
        FacultyStatus.busy         => 'Busy',
        FacultyStatus.inLecture    => 'In Lecture',
        FacultyStatus.away         => 'Away',
        FacultyStatus.meeting      => 'In Meeting',
        FacultyStatus.notAvailable => 'Not Available',
        FacultyStatus.onHoliday    => 'On Holiday',
        FacultyStatus.custom       => 'Custom',
      };

  Color get color => switch (this) {
        FacultyStatus.available    => AppColors.available,
        FacultyStatus.busy         => AppColors.busy,
        FacultyStatus.inLecture    => AppColors.inLecture,
        FacultyStatus.away         => AppColors.away,
        FacultyStatus.meeting      => AppColors.meeting,
        FacultyStatus.notAvailable => AppColors.notAvailable,
        FacultyStatus.onHoliday    => const Color(0xFF0891B2), // cyan-600
        FacultyStatus.custom       => const Color(0xFF7C3AED), // violet-700
      };

  IconData get icon => switch (this) {
        FacultyStatus.available    => Icons.check_circle,
        FacultyStatus.busy         => Icons.schedule,
        FacultyStatus.inLecture    => Icons.mic,
        FacultyStatus.away         => Icons.directions_walk,
        FacultyStatus.meeting      => Icons.groups,
        FacultyStatus.notAvailable => Icons.cancel,
        FacultyStatus.onHoliday    => Icons.beach_access_rounded,
        FacultyStatus.custom       => Icons.edit_note_rounded,
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
  /// For FacultyStatus.custom — the faculty's own status text
  final String? customStatusText;

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
    this.customStatusText,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get isAvailable => status == FacultyStatus.available;

  bool get hasManualOverride =>
      manualOverrideUntil != null && manualOverrideUntil!.isAfter(DateTime.now());

  /// Display label — shows custom text when status is custom
  String get displayStatus {
    if (status == FacultyStatus.custom && customStatusText != null && customStatusText!.isNotEmpty) {
      return customStatusText!;
    }
    return status.label;
  }

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
    String? customStatusText,
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
      customStatusText: customStatusText ?? this.customStatusText,
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, department, building, cabinId, status, zone,
        specialization, bio, avatarUrl, phoneNumber, publicationsCount,
        rating, consultationCount, lastUpdated, expectedReturnAt,
        manualOverrideUntil, activeContext, customStatusText,
      ];
}
