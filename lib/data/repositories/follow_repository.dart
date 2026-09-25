import '../models/faculty_model.dart';
import '../models/follow_entry_model.dart';
import '../services/follow_service.dart';

class FollowRepository {
  FollowRepository(this._service);

  final FollowService _service;

  Future<void> followFaculty({
    required String studentId,
    required String facultyId,
  }) {
    return _service.followFaculty(studentId: studentId, facultyId: facultyId);
  }

  Future<void> unfollowFaculty({
    required String studentId,
    required String facultyId,
  }) {
    return _service.unfollowFaculty(studentId: studentId, facultyId: facultyId);
  }

  Future<List<FollowEntryModel>> fetchFollowEntries(String studentId) {
    return _service.fetchFollowEntries(studentId);
  }

  Stream<List<FollowEntryModel>> watchFollowEntries(String studentId) {
    return _service.watchFollowEntries(studentId);
  }

  Future<List<FacultyModel>> fetchFollowedFaculty(String studentId) {
    return _service.fetchFollowedFaculty(studentId);
  }
}
