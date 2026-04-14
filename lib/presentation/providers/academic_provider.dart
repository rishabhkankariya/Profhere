import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/academic.dart';
import '../../data/repositories/firestore_timetable_repository.dart';
import 'auth_provider.dart';

final timetableRepositoryProvider = Provider<FirestoreTimetableRepository>((ref) {
  return FirestoreTimetableRepository();
});

/// Faculty timetable — auth-gated to avoid permission-denied before login
final facultyTimetableProvider =
    FutureProvider.family<List<TimetableEntry>, String>((ref, facultyId) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return [];
  return ref.watch(timetableRepositoryProvider).getByFaculty(facultyId);
});

// ─── Timetable Notifier ───────────────────────────────────────────────────────

class TimetableNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreTimetableRepository _repo;
  final Ref _ref;

  TimetableNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> addEntry(TimetableEntry entry) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addEntry(entry);
      _ref.invalidate(facultyTimetableProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEntry(TimetableEntry entry) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateEntry(entry);
      _ref.invalidate(facultyTimetableProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteEntry(id);
      _ref.invalidate(facultyTimetableProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final timetableNotifierProvider =
    StateNotifierProvider<TimetableNotifier, AsyncValue<void>>((ref) {
  return TimetableNotifier(ref.watch(timetableRepositoryProvider), ref);
});
