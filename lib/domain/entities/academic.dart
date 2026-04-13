import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id;
  final String code;
  final String name;
  final String facultyId;
  final String? facultyName;
  final String description;
  final int credits;
  final Map<String, int> markScheme;

  const Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.facultyId,
    this.facultyName,
    this.description = '',
    this.credits = 3,
    this.markScheme = const {},
  });

  @override
  List<Object?> get props => [id, code, name, facultyId, facultyName, description, credits, markScheme];
}

class StudentMark extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String subjectId;
  final String? subjectName;
  final Map<String, double> scores;
  final double? totalMarks;
  final double? percentage;
  final String? grade;
  final DateTime? lastUpdated;

  const StudentMark({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    this.subjectName,
    required this.scores,
    this.totalMarks,
    this.percentage,
    this.grade,
    this.lastUpdated,
  });

  double get calculatedTotal => scores.values.fold(0, (sum, item) => sum + item);

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        subjectId,
        subjectName,
        scores,
        totalMarks,
        percentage,
        grade,
        lastUpdated,
      ];
}

class TimetableEntry extends Equatable {
  final String id;
  final String subjectId;
  final String subjectName;
  final String facultyId;
  final String? facultyName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String room;
  final bool isActive;

  const TimetableEntry({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.facultyId,
    this.facultyName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.isActive = false,
  });

  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek - 1];
  }

  String get timeRange => '$startTime - $endTime';

  @override
  List<Object?> get props => [
        id,
        subjectId,
        subjectName,
        facultyId,
        facultyName,
        dayOfWeek,
        startTime,
        endTime,
        room,
        isActive,
      ];
}

class GPAData extends Equatable {
  final double gpa;
  final double maxGpa;
  final double percentage;
  final int rank;
  final int totalStudents;
  final String cohort;
  final String? message;

  const GPAData({
    required this.gpa,
    this.maxGpa = 4.0,
    required this.percentage,
    this.rank = 0,
    this.totalStudents = 0,
    this.cohort = '2024',
    this.message,
  });

  @override
  List<Object?> get props => [gpa, maxGpa, percentage, rank, totalStudents, cohort, message];
}
