import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/academic.dart';
import '../../domain/entities/faculty.dart';
import '../../data/repositories/hive_academic_repository.dart';
import 'faculty_provider.dart';

final academicRepositoryProvider = Provider<HiveAcademicRepository>((ref) {
  return HiveAcademicRepository();
});

/// One timetable row plus the teaching faculty's live status (for the hub grid).
class TimetableSlotWithFaculty {
  final TimetableEntry entry;
  final FacultyStatus facultyStatus;

  const TimetableSlotWithFaculty({
    required this.entry,
    required this.facultyStatus,
  });
}

/// Aggregates all faculty slots for a single weekday (1 = Monday … 7 = Sunday).
final timetableSlotsForDayProvider =
    FutureProvider.family<List<TimetableSlotWithFaculty>, int>((ref, dayOfWeek) async {
  final facultyRepo = ref.watch(facultyRepositoryProvider);
  final academicRepo = ref.watch(academicRepositoryProvider);
  final faculties = await facultyRepo.getFacultiesOnce();
  final out = <TimetableSlotWithFaculty>[];
  for (final faculty in faculties) {
    final entries = await academicRepo.getTimetableByFaculty(faculty.id);
    for (final entry in entries) {
      if (entry.dayOfWeek == dayOfWeek) {
        out.add(TimetableSlotWithFaculty(
          entry: entry,
          facultyStatus: faculty.status,
        ));
      }
    }
  }
  out.sort((a, b) => a.entry.startTime.compareTo(b.entry.startTime));
  return out;
});

final subjectsProvider = FutureProvider<List<Subject>>((ref) {
  final repo = ref.watch(academicRepositoryProvider);
  return repo.getSubjects();
});

final selectedSubjectIdProvider = StateProvider<String?>((ref) => null);

final studentMarksProvider = FutureProvider<List<StudentMark>>((ref) {
  final subjectId = ref.watch(selectedSubjectIdProvider);
  if (subjectId == null) return [];
  
  final repo = ref.watch(academicRepositoryProvider);
  return repo.getStudentMarks(subjectId);
});

final facultyTimetableProvider = FutureProvider.family<List<TimetableEntry>, String>((ref, facultyId) {
  final repo = ref.watch(academicRepositoryProvider);
  return repo.getTimetableByFaculty(facultyId);
});

final gpaDataProvider = FutureProvider.family<GPAData, String>((ref, studentId) {
  final repo = ref.watch(academicRepositoryProvider);
  return repo.getGPAData(studentId);
});

// ─── Timetable Notifier ───────────────────────────────────────────────────────
// Faculty can add, edit and delete their own schedule entries.

class TimetableNotifier extends StateNotifier<AsyncValue<void>> {
  final HiveAcademicRepository _repo;
  final Ref _ref;

  TimetableNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> addEntry(TimetableEntry entry) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addTimetableEntry(entry);
      // Invalidate so the schedule tab re-fetches
      _ref.invalidate(facultyTimetableProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEntry(TimetableEntry entry) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateTimetableEntry(entry);
      _ref.invalidate(facultyTimetableProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteTimetableEntry(id);
      _ref.invalidate(facultyTimetableProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final timetableNotifierProvider =
    StateNotifierProvider<TimetableNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(academicRepositoryProvider);
  return TimetableNotifier(repo, ref);
});
