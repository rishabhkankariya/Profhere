import '../entities/faculty.dart';

abstract class FacultyRepository {
  Stream<List<Faculty>> getFaculties();
  Future<List<Faculty>> getFacultiesOnce();
  Future<Faculty?> getFacultyById(String id);
  Future<void> updateFacultyStatus(
    String id,
    FacultyStatus status, {
    String? activeContext,
    DateTime? expectedReturnAt,
    DateTime? manualOverrideUntil,
    String? customStatusText,
  });
  Future<void> addFaculty(Faculty faculty);
  Future<void> updateFaculty(Faculty faculty);
  Future<void> deleteFaculty(String id);
}
