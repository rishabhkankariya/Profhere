import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/database_constants.dart';
import '../models/faculty_model.dart';
import '../models/follow_entry_model.dart';

class FollowService {
  FollowService(this._client);

  final SupabaseClient _client;

  Future<void> followFaculty({
    required String studentId,
    required String facultyId,
  }) async {
    await _client.from(DatabaseConstants.followTable).upsert(<String, dynamic>{
      'student_id': studentId,
      'faculty_id': facultyId,
    });
  }

  Future<void> unfollowFaculty({
    required String studentId,
    required String facultyId,
  }) {
    return _client
        .from(DatabaseConstants.followTable)
        .delete()
        .eq('student_id', studentId)
        .eq('faculty_id', facultyId);
  }

  Future<List<FollowEntryModel>> fetchFollowEntries(String studentId) async {
    final response = await _client
        .from(DatabaseConstants.followTable)
        .select()
        .eq('student_id', studentId)
        .order('created_at');

    return response
        .map(
          (item) => FollowEntryModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Stream<List<FollowEntryModel>> watchFollowEntries(String studentId) {
    return _client
        .from(DatabaseConstants.followTable)
        .stream(primaryKey: const ['id'])
        .eq('student_id', studentId)
        .order('created_at')
        .map(
          (rows) => rows
              .map(
                (item) => FollowEntryModel.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
  }

  Future<List<FacultyModel>> fetchFollowedFaculty(String studentId) async {
    final followEntries = await fetchFollowEntries(studentId);
    if (followEntries.isEmpty) {
      return const <FacultyModel>[];
    }

    final facultyIds = followEntries.map((entry) => entry.facultyId).toList();
    final response = await _client
        .from(DatabaseConstants.facultyTable)
        .select()
        .inFilter('id', facultyIds)
        .order('name');

    return response
        .map((item) => FacultyModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}
