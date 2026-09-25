import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/database_constants.dart';
import '../models/faculty_model.dart';

class FacultyRepository {
  FacultyRepository(this._client);

  final SupabaseClient _client;

  Future<List<FacultyModel>> fetchFacultyList() async {
    final response = await _client
        .from(DatabaseConstants.facultyTable)
        .select()
        .order('name');

    return response
        .map((item) => FacultyModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Stream<List<FacultyModel>> watchFacultyList() {
    return _client
        .from(DatabaseConstants.facultyTable)
        .stream(primaryKey: const ['id'])
        .order('name')
        .map(
          (rows) => rows
              .map((item) => FacultyModel.fromMap(Map<String, dynamic>.from(item)))
              .toList(),
        );
  }

  Future<FacultyModel?> fetchFacultyByUserId(String userId) async {
    final response = await _client
        .from(DatabaseConstants.facultyTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return FacultyModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<FacultyModel> updateFacultyProfile({
    required String facultyId,
    required String name,
    required String cabin,
  }) async {
    final response = await _client
        .from(DatabaseConstants.facultyTable)
        .update(<String, dynamic>{'name': name, 'cabin': cabin})
        .eq('id', facultyId)
        .select()
        .single();

    return FacultyModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<FacultyModel> updateFacultyStatus({
    required String facultyId,
    required String status,
  }) async {
    final response = await _client
        .from(DatabaseConstants.facultyTable)
        .update(<String, dynamic>{'status': status})
        .eq('id', facultyId)
        .select()
        .single();

    return FacultyModel.fromMap(Map<String, dynamic>.from(response));
  }
}
