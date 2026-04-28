import 'package:equatable/equatable.dart';

enum LocationAccessStatus {
  pending,
  approved,
  rejected,
  revoked;

  String get label => switch (this) {
        LocationAccessStatus.pending => 'Pending',
        LocationAccessStatus.approved => 'Approved',
        LocationAccessStatus.rejected => 'Rejected',
        LocationAccessStatus.revoked => 'Revoked',
      };
}

/// Represents a student's request to access faculty's real-time location via NodeMCU
class LocationAccess extends Equatable {
  final String id;
  final String facultyId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final LocationAccessStatus status;
  final String? nodeMcuIpAddress; // Faculty's NodeMCU IP (only visible if approved)
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? revokedAt;
  final String? reason; // Reason for rejection/revocation

  const LocationAccess({
    required this.id,
    required this.facultyId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    this.nodeMcuIpAddress,
    required this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.revokedAt,
    this.reason,
  });

  bool get isPending => status == LocationAccessStatus.pending;
  bool get isApproved => status == LocationAccessStatus.approved;
  bool get isRejected => status == LocationAccessStatus.rejected;
  bool get isRevoked => status == LocationAccessStatus.revoked;

  LocationAccess copyWith({
    String? id,
    String? facultyId,
    String? studentId,
    String? studentName,
    String? studentEmail,
    LocationAccessStatus? status,
    String? nodeMcuIpAddress,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    DateTime? revokedAt,
    String? reason,
  }) {
    return LocationAccess(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      status: status ?? this.status,
      nodeMcuIpAddress: nodeMcuIpAddress ?? this.nodeMcuIpAddress,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        facultyId,
        studentId,
        studentName,
        studentEmail,
        status,
        nodeMcuIpAddress,
        requestedAt,
        approvedAt,
        rejectedAt,
        revokedAt,
        reason,
      ];
}
