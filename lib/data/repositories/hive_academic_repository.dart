import 'package:profhere/data/datasources/local/hive_service.dart';
import 'package:profhere/data/models/academic_model.dart';
import 'package:profhere/domain/entities/academic.dart';
import 'package:profhere/domain/repositories/academic_repository.dart';
import 'package:uuid/uuid.dart';

class HiveAcademicRepository implements AcademicRepository {
  final _uuid = const Uuid();

  @override
  Future<List<Subject>> getSubjects() async {
    return HiveService.subjects
        .values
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<void> saveSubject(Subject subject) async {
    final box = HiveService.subjects;
    final id = subject.id.isEmpty ? _uuid.v4() : subject.id;
    final model = SubjectModel.fromEntity(subject.copyWith(id: id));
    await box.put(id, model);
  }

  @override
  Future<void> deleteSubject(String id) async {
    await HiveService.subjects.delete(id);
  }

  @override
  Future<List<StudentMark>> getStudentMarks(String subjectId) async {
    return HiveService.marks
        .values
        .where((m) => m.subjectId == subjectId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<void> updateStudentMarks(StudentMark marks) async {
    final box = HiveService.marks;
    final id = marks.id.isEmpty ? _uuid.v4() : marks.id;
    final model = StudentMarkModel.fromEntity(marks.copyWith(id: id));
    await box.put(id, model);
  }

  @override
  Future<void> deleteStudentMarks(String id) async {
    await HiveService.marks.delete(id);
  }

  @override
  Future<List<TimetableEntry>> getTimetableByFaculty(String facultyId) async {
    return HiveService.timetable
        .values
        .where((m) => m.facultyId == facultyId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<void> addTimetableEntry(TimetableEntry entry) async {
    final box = HiveService.timetable;
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    final model = TimetableModel.fromEntity(entry.copyWith(id: id));
    await box.put(id, model);
  }

  @override
  Future<void> updateTimetableEntry(TimetableEntry entry) async {
    final model = TimetableModel.fromEntity(entry);
    await HiveService.timetable.put(entry.id, model);
  }

  @override
  Future<void> deleteTimetableEntry(String id) async {
    await HiveService.timetable.delete(id);
  }

  @override
  Future<GPAData> getGPAData(String studentId) async {
    if (studentId.isEmpty) {
      return const GPAData(
        gpa: 0,
        maxGpa: 4.0,
        percentage: 0,
        rank: 0,
        totalStudents: 0,
      );
    }
    // Demo aggregate; real app would compute from [HiveService.marks] per programme rules.
    return const GPAData(
      gpa: 3.82,
      maxGpa: 4.0,
      percentage: 92.5,
      rank: 4,
      totalStudents: 85,
    );
  }
}

// Extension to help with copyWith on entities
extension on Subject {
  Subject copyWith({String? id}) => Subject(
    id: id ?? this.id,
    code: code,
    name: name,
    facultyId: facultyId,
    facultyName: facultyName,
    description: description,
    credits: credits,
    markScheme: markScheme,
  );
}

extension on StudentMark {
  StudentMark copyWith({String? id}) => StudentMark(
    id: id ?? this.id,
    studentId: studentId,
    studentName: studentName,
    subjectId: subjectId,
    scores: scores,
    lastUpdated: lastUpdated,
  );
}

extension on TimetableEntry {
  TimetableEntry copyWith({String? id}) => TimetableEntry(
    id: id ?? this.id,
    subjectId: subjectId,
    subjectName: subjectName,
    facultyId: facultyId,
    dayOfWeek: dayOfWeek,
    startTime: startTime,
    endTime: endTime,
    room: room,
  );
}
