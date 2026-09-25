import '../../domain/entities/queue_entry.dart';

class QueueEntryModel extends QueueEntry {
  const QueueEntryModel({
    required super.id,
    required super.facultyId,
    required super.studentId,
    super.studentName,
    required super.position,
    required super.status,
    super.calledAt,
    required super.createdAt,
  });

  factory QueueEntryModel.fromMap(Map<String, dynamic> map) {
    return QueueEntryModel(
      id: map['id'] as String,
      facultyId: map['faculty_id'] as String,
      studentId: map['student_id'] as String,
      studentName: _resolveStudentName(map),
      position: (map['position'] as num?)?.toInt() ?? 0,
      status: QueueEntryStatus.fromValue(
        map['status'] as String? ?? QueueEntryStatus.waiting.value,
      ),
      calledAt: DateTime.tryParse(map['called_at'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'faculty_id': facultyId,
      'student_id': studentId,
      'student_name': studentName,
      'position': position,
      'status': status.value,
      'called_at': calledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  QueueEntryModel copyWith({
    String? id,
    String? facultyId,
    String? studentId,
    String? studentName,
    int? position,
    QueueEntryStatus? status,
    DateTime? calledAt,
    DateTime? createdAt,
  }) {
    return QueueEntryModel(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      position: position ?? this.position,
      status: status ?? this.status,
      calledAt: calledAt ?? this.calledAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String? _resolveStudentName(Map<String, dynamic> map) {
    final nestedUser = map['users'];
    if (nestedUser is Map<String, dynamic>) {
      return nestedUser['full_name'] as String?;
    }

    if (nestedUser is Map) {
      return nestedUser['full_name'] as String?;
    }

    return map['student_name'] as String?;
  }
}
