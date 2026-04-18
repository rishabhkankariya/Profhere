import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/academic.dart';
import '../../data/repositories/firestore_timetable_repository.dart';
import '../../core/services/audio_service.dart';

final timetableRepositoryProvider = Provider<FirestoreTimetableRepository>((ref) {
  return FirestoreTimetableRepository();
});

/// Faculty timetable — use StreamProvider so UI updates live after add/edit/delete
final facultyTimetableProvider =
    StreamProvider.family<List<TimetableEntry>, String>((ref, facultyId) {
  return ref.watch(timetableRepositoryProvider).watchByFaculty(facultyId);
});

// ─── Timetable Notifier ───────────────────────────────────────────────────────

class TimetableNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreTimetableRepository _repo;

  TimetableNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<bool> addEntry(TimetableEntry entry) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addEntry(entry);
      state = const AsyncValue.data(null);
      AudioService.play(AppSound.success);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AudioService.play(AppSound.error);
      return false;
    }
  }

  Future<bool> updateEntry(TimetableEntry entry) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateEntry(entry);
      state = const AsyncValue.data(null);
      AudioService.play(AppSound.success);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AudioService.play(AppSound.error);
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteEntry(id);
      state = const AsyncValue.data(null);
      AudioService.play(AppSound.success);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AudioService.play(AppSound.error);
      return false;
    }
  }
}

final timetableNotifierProvider =
    StateNotifierProvider<TimetableNotifier, AsyncValue<void>>((ref) {
  return TimetableNotifier(ref.watch(timetableRepositoryProvider));
});
