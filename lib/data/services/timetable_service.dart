import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/database_constants.dart';
import '../models/timetable_slot_model.dart';

class TimetableService {
  TimetableService(this._client);

  final SupabaseClient _client;

  Future<List<TimetableSlotModel>> fetchTimetableSlots() async {
    final response = await _client
        .from(DatabaseConstants.timetableTable)
        .select()
        .order('day_of_week')
        .order('start_time');

    return response
        .map(
          (item) => TimetableSlotModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Stream<List<TimetableSlotModel>> watchTimetableSlots() {
    return _client
        .from(DatabaseConstants.timetableTable)
        .stream(primaryKey: const ['id'])
        .order('day_of_week')
        .order('start_time')
        .map(
          (rows) => rows
              .map(
                (item) =>
                    TimetableSlotModel.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
  }
}
