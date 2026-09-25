import '../../domain/entities/timetable_slot.dart';

class TimetableSlotModel extends TimetableSlot {
  const TimetableSlotModel({
    required super.id,
    required super.facultyId,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
    required super.subject,
  });

  factory TimetableSlotModel.fromMap(Map<String, dynamic> map) {
    return TimetableSlotModel(
      id: map['id'] as String,
      facultyId: map['faculty_id'] as String,
      dayOfWeek: map['day_of_week'] as String? ?? '',
      startTime: map['start_time'] as String? ?? '',
      endTime: map['end_time'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
    );
  }
}
