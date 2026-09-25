import '../../domain/entities/faculty.dart';

class FacultyModel extends Faculty {
  const FacultyModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.status,
    required super.cabin,
    required super.department,
  });

  factory FacultyModel.fromMap(Map<String, dynamic> map) {
    return FacultyModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String? ?? '',
      status: map['status'] as String? ?? 'Available',
      cabin: map['cabin'] as String? ?? 'Not assigned',
      department: map['department'] as String? ?? 'General',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'status': status,
      'cabin': cabin,
      'department': department,
    };
  }

  @override
  FacultyModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? status,
    String? cabin,
    String? department,
  }) {
    return FacultyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      status: status ?? this.status,
      cabin: cabin ?? this.cabin,
      department: department ?? this.department,
    );
  }
}
