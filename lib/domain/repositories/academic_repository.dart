import 'package:profhere/domain/entities/academic.dart';

abstract class AcademicRepository {
  Future<List<Subject>> getSubjects();
  Future<void> saveSubject(Subject subject);
  Future<void> deleteSubject(String id);
  
  Future<List<StudentMark>> getStudentMarks(String subjectId);
  Future<void> updateStudentMarks(StudentMark marks);
  Future<void> deleteStudentMarks(String id);
  
  Future<List<TimetableEntry>> getTimetableByFaculty(String facultyId);
  Future<void> addTimetableEntry(TimetableEntry entry);
  Future<void> updateTimetableEntry(TimetableEntry entry);
  Future<void> deleteTimetableEntry(String id);
  
  Future<GPAData> getGPAData(String studentId);
}
