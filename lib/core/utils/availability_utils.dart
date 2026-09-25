import '../../domain/entities/timetable_slot.dart';

abstract final class AvailabilityUtils {
  static const String available = 'Available';
  static const String busy = 'Busy';

  static String computeFacultyStatus({
    required List<TimetableSlot> timetableSlots,
    DateTime? now,
  }) {
    final currentDateTime = now ?? DateTime.now();
    final currentDay = _dayName(currentDateTime.weekday);
    final currentMinute = currentDateTime.hour * 60 + currentDateTime.minute;

    for (final slot in timetableSlots) {
      if (slot.dayOfWeek != currentDay) {
        continue;
      }

      final startMinute = _parseMinutes(slot.startTime);
      final endMinute = _parseMinutes(slot.endTime);
      if (startMinute == null || endMinute == null) {
        continue;
      }

      if (currentMinute >= startMinute && currentMinute < endMinute) {
        return busy;
      }
    }

    return available;
  }

  static String _dayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  static int? _parseMinutes(String value) {
    final segments = value.split(':');
    if (segments.length < 2) {
      return null;
    }

    final hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return (hour * 60) + minute;
  }
}
