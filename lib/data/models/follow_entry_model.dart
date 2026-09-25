import '../../domain/entities/follow_entry.dart';

class FollowEntryModel extends FollowEntry {
  const FollowEntryModel({
    required super.id,
    required super.studentId,
    required super.facultyId,
    required super.createdAt,
  });

  factory FollowEntryModel.fromMap(Map<String, dynamic> map) {
    return FollowEntryModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      facultyId: map['faculty_id'] as String,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'student_id': studentId,
      'faculty_id': facultyId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
