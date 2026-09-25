import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/availability_utils.dart';
import '../../data/repositories/faculty_repository.dart';
import '../../data/services/timetable_service.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/timetable_slot.dart';
import 'supabase_provider.dart';

final facultyRepositoryProvider = Provider<FacultyRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return FacultyRepository(client);
});

final timetableServiceProvider = Provider<TimetableService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return TimetableService(client);
});

final facultyListProvider = StreamProvider<List<Faculty>>((ref) {
  final repository = ref.watch(facultyRepositoryProvider);
  final timetableService = ref.watch(timetableServiceProvider);
  if (repository == null || timetableService == null) {
    return Stream<List<Faculty>>.value(const <Faculty>[]);
  }

  return Stream<List<Faculty>>.multi((controller) {
    StreamSubscription<List<Faculty>>? facultySubscription;
    StreamSubscription<List<TimetableSlot>>? timetableSubscription;
    List<Faculty> currentFaculty = const <Faculty>[];
    List<TimetableSlot> currentTimetable = const <TimetableSlot>[];

    void emitCombined() {
      final updatedFaculty = currentFaculty.map((faculty) {
        final facultyTimetable = currentTimetable
            .where((slot) => slot.facultyId == faculty.id)
            .toList();
        final computedStatus = AvailabilityUtils.computeFacultyStatus(
          timetableSlots: facultyTimetable,
        );
        return faculty.copyWith(status: computedStatus);
      }).toList();

      controller.add(updatedFaculty);
    }

    facultySubscription = repository.watchFacultyList().listen((faculty) {
      currentFaculty = faculty;
      emitCombined();
    }, onError: controller.addError);

    timetableSubscription = timetableService.watchTimetableSlots().listen((
      timetable,
    ) {
      currentTimetable = timetable;
      emitCombined();
    }, onError: controller.addError);

    ref.onDispose(() {
      unawaited(facultySubscription?.cancel());
      unawaited(timetableSubscription?.cancel());
    });
  });
});
