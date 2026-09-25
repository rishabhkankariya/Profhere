import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/database_constants.dart';
import 'excel_service.dart';

class TimetableImportService {
  TimetableImportService(this._client);

  final SupabaseClient _client;

  Future<TimetableImportResult> importRows(
    List<TimetableImportRow> rows,
  ) async {
    if (rows.isEmpty) {
      return const TimetableImportResult(importedCount: 0, errors: <String>[]);
    }

    final facultyRows = await _client
        .from(DatabaseConstants.facultyTable)
        .select('id, name');

    final facultyByName = <String, String>{
      for (final faculty in facultyRows)
        (faculty['name'] as String).trim().toLowerCase(): faculty['id'] as String,
    };

    final inserts = <Map<String, dynamic>>[];
    final errors = <String>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final normalizedFaculty = row.facultyName.trim().toLowerCase();
      final facultyId = facultyByName[normalizedFaculty];
      if (facultyId == null) {
        errors.add('Row ${i + 2}: Faculty "${row.facultyName}" not found.');
        continue;
      }

      if (!_isValidDay(row.dayOfWeek)) {
        errors.add('Row ${i + 2}: Invalid day "${row.dayOfWeek}".');
        continue;
      }

      final startTime = _normalizeTime(row.startTime);
      final endTime = _normalizeTime(row.endTime);
      if (startTime == null || endTime == null) {
        errors.add(
          'Row ${i + 2}: Invalid time format. Use HH:MM or HH:MM:SS.',
        );
        continue;
      }

      inserts.add(<String, dynamic>{
        'faculty_id': facultyId,
        'day_of_week': _normalizeDay(row.dayOfWeek),
        'start_time': startTime,
        'end_time': endTime,
        'subject': row.subject.trim().isEmpty ? 'Imported Slot' : row.subject,
      });
    }

    if (inserts.isNotEmpty) {
      await _client.from(DatabaseConstants.timetableTable).insert(inserts);
    }

    return TimetableImportResult(
      importedCount: inserts.length,
      errors: errors,
    );
  }

  bool _isValidDay(String value) {
    return _days.contains(_normalizeDay(value));
  }

  String _normalizeDay(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return '';
    }

    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  String? _normalizeTime(String value) {
    final segments = value.trim().split(':');
    if (segments.length < 2 || segments.length > 3) {
      return null;
    }

    final hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    final second = segments.length == 3 ? int.tryParse(segments[2]) : 0;

    if (hour == null ||
        minute == null ||
        second == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return null;
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  static const Set<String> _days = <String>{
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  };
}

class TimetableImportResult {
  const TimetableImportResult({
    required this.importedCount,
    required this.errors,
  });

  final int importedCount;
  final List<String> errors;
}
