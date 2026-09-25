import 'package:flutter_test/flutter_test.dart';
import 'package:profhere/core/utils/availability_utils.dart';
import 'package:profhere/domain/entities/timetable_slot.dart';

void main() {
  test('returns busy when current time is inside a timetable slot', () {
    const slots = <TimetableSlot>[
      TimetableSlot(
        id: '1',
        facultyId: 'faculty-1',
        dayOfWeek: 'Monday',
        startTime: '09:00:00',
        endTime: '10:00:00',
        subject: 'Math',
      ),
    ];

    final status = AvailabilityUtils.computeFacultyStatus(
      timetableSlots: slots,
      now: DateTime(2026, 3, 23, 9, 30),
    );

    expect(status, AvailabilityUtils.busy);
  });

  test('returns available when current time is outside timetable slots', () {
    const slots = <TimetableSlot>[
      TimetableSlot(
        id: '1',
        facultyId: 'faculty-1',
        dayOfWeek: 'Monday',
        startTime: '09:00:00',
        endTime: '10:00:00',
        subject: 'Math',
      ),
    ];

    final status = AvailabilityUtils.computeFacultyStatus(
      timetableSlots: slots,
      now: DateTime(2026, 3, 23, 11, 0),
    );

    expect(status, AvailabilityUtils.available);
  });
}
