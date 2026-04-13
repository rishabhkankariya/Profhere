import 'package:equatable/equatable.dart';

enum ConsultationStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  delayed;

  String get label => switch (this) {
        ConsultationStatus.pending => 'Waiting',
        ConsultationStatus.inProgress => 'In Progress',
        ConsultationStatus.completed => 'Completed',
        ConsultationStatus.cancelled => 'Cancelled',
        ConsultationStatus.delayed => 'Delayed',
      };
}

class Consultation extends Equatable {
  final String id;
  final String facultyId;
  final String studentId;
  final String studentName;
  final String purpose;
  final String? notes;
  final ConsultationStatus status;
  final DateTime requestedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int position;
  final int waitTimeMinutes;

  const Consultation({
    required this.id,
    required this.facultyId,
    required this.studentId,
    required this.studentName,
    required this.purpose,
    this.notes,
    required this.status,
    required this.requestedAt,
    this.startedAt,
    this.completedAt,
    required this.position,
    this.waitTimeMinutes = 0,
  });

  bool get isWaiting => status == ConsultationStatus.pending;
  bool get isInProgress => status == ConsultationStatus.inProgress;
  bool get isCompleted => status == ConsultationStatus.completed;

  Consultation copyWith({
    String? id,
    String? facultyId,
    String? studentId,
    String? studentName,
    String? purpose,
    String? notes,
    ConsultationStatus? status,
    DateTime? requestedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? position,
    int? waitTimeMinutes,
  }) {
    return Consultation(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      position: position ?? this.position,
      waitTimeMinutes: waitTimeMinutes ?? this.waitTimeMinutes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        facultyId,
        studentId,
        studentName,
        purpose,
        notes,
        status,
        requestedAt,
        startedAt,
        completedAt,
        position,
        waitTimeMinutes,
      ];
}
