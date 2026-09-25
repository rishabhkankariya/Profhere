import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/database_constants.dart';
import '../../core/utils/queue_utils.dart';
import '../../domain/entities/queue_entry.dart';
import '../models/queue_entry_model.dart';

class QueueService {
  QueueService(this._client);

  final SupabaseClient _client;

  Future<List<QueueEntryModel>> fetchQueueForFaculty(String facultyId) async {
    final response = await _client
        .from(DatabaseConstants.queueTable)
        .select('*, users!queue_student_id_fkey(full_name)')
        .eq('faculty_id', facultyId)
        .order('position');

    return response
        .map((item) => QueueEntryModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Stream<List<QueueEntryModel>> watchQueueForFaculty(String facultyId) {
    return _client
        .from(DatabaseConstants.queueTable)
        .stream(primaryKey: const ['id'])
        .eq('faculty_id', facultyId)
        .order('position')
        .asyncMap((rows) async {
          final mappedRows = rows
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          final studentIds = mappedRows
              .map((item) => item['student_id'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          Map<String, String> studentNamesById = const <String, String>{};
          if (studentIds.isNotEmpty) {
            final users = await _client
                .from(DatabaseConstants.usersTable)
                .select('id, full_name')
                .inFilter('id', studentIds);

            studentNamesById = <String, String>{
              for (final user in users)
                user['id'] as String:
                    (user['full_name'] as String?) ?? 'Student',
            };
          }

          return mappedRows.map((item) {
            item['student_name'] =
                studentNamesById[item['student_id']] ?? 'Student';
            return QueueEntryModel.fromMap(item);
          }).toList();
        });
  }

  Stream<List<QueueEntryModel>> watchQueueForStudent(String studentId) {
    return _client
        .from(DatabaseConstants.queueTable)
        .stream(primaryKey: const ['id'])
        .eq('student_id', studentId)
        .order('created_at')
        .map(
          (rows) => rows
              .map(
                (item) =>
                    QueueEntryModel.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
  }

  Future<QueueEntryModel> joinQueue({
    required String facultyId,
    required String studentId,
  }) async {
    final existingEntry = await _client
        .from(DatabaseConstants.queueTable)
        .select()
        .eq('faculty_id', facultyId)
        .eq('student_id', studentId)
        .neq('status', QueueEntryStatus.completed.value)
        .maybeSingle();

    if (existingEntry != null) {
      return QueueEntryModel.fromMap(Map<String, dynamic>.from(existingEntry));
    }

    final currentQueue = await _client
        .from(DatabaseConstants.queueTable)
        .select('position')
        .eq('faculty_id', facultyId)
        .order('position', ascending: false)
        .limit(1);

    final maxPosition = currentQueue.isEmpty
        ? 0
        : ((currentQueue.first['position'] as num?)?.toInt() ?? 0);

    final response = await _client
        .from(DatabaseConstants.queueTable)
        .insert(<String, dynamic>{
          'faculty_id': facultyId,
          'student_id': studentId,
          'position': maxPosition + 1,
          'status': QueueEntryStatus.waiting.value,
        })
        .select()
        .single();

    return QueueEntryModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<QueueEntryModel> updateQueueStatus({
    required String queueEntryId,
    required QueueEntryStatus status,
  }) async {
    final payload = <String, dynamic>{'status': status.value};
    if (status == QueueEntryStatus.called) {
      payload['called_at'] = DateTime.now().toIso8601String();
    }

    final response = await _client
        .from(DatabaseConstants.queueTable)
        .update(payload)
        .eq('id', queueEntryId)
        .select()
        .single();

    return QueueEntryModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<QueueEntryModel?> callNextStudent(String facultyId) async {
    final queueEntries = await fetchQueueForFaculty(facultyId);
    final nextEntry = QueueUtils.findNextWaitingEntry(queueEntries);
    if (nextEntry == null) {
      return null;
    }

    return updateQueueStatus(
      queueEntryId: nextEntry.id,
      status: QueueEntryStatus.called,
    );
  }
}
