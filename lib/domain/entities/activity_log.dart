import 'package:equatable/equatable.dart';

enum ActivityType {
  facultyStatusUpdated,
  facultyAdded,
  facultyRemoved,
  consultationStarted,
  consultationCompleted,
  consultationCancelled,
  userLogin,
  userLogout,
  markUploaded,
  timetableUpdated;

  String get label => switch (this) {
        ActivityType.facultyStatusUpdated => 'Status Updated',
        ActivityType.facultyAdded => 'Faculty Added',
        ActivityType.facultyRemoved => 'Faculty Removed',
        ActivityType.consultationStarted => 'Consultation Started',
        ActivityType.consultationCompleted => 'Consultation Completed',
        ActivityType.consultationCancelled => 'Consultation Cancelled',
        ActivityType.userLogin => 'User Login',
        ActivityType.userLogout => 'User Logout',
        ActivityType.markUploaded => 'Marks Uploaded',
        ActivityType.timetableUpdated => 'Timetable Updated',
      };
}

class ActivityLog extends Equatable {
  final String id;
  final ActivityType action;
  final String actorId;
  final String actorName;
  final String? actorRole;
  final String? targetId;
  final String? targetName;
  final String? statusLabel;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.action,
    required this.actorId,
    required this.actorName,
    this.actorRole,
    this.targetId,
    this.targetName,
    this.statusLabel,
    this.metadata,
    required this.createdAt,
  });

  String get displayTitle {
    if (targetName != null) {
      return '$targetName - ${action.label}';
    }
    return action.label;
  }

  String get displaySubtitle {
    if (statusLabel != null) {
      return '${action.label}: $statusLabel';
    }
    if (actorRole != null) {
      return 'By: $actorName ($actorRole)';
    }
    return 'By: $actorName';
  }

  @override
  List<Object?> get props => [
        id,
        action,
        actorId,
        actorName,
        actorRole,
        targetId,
        targetName,
        statusLabel,
        metadata,
        createdAt,
      ];
}
