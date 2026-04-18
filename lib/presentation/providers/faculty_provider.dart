import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_faculty_repository.dart';
import '../../domain/entities/faculty.dart';

final facultyRepositoryProvider = Provider<FirestoreFacultyRepository>((ref) {
  return FirestoreFacultyRepository();
});

// ── Faculty list — live Firestore stream ──────────────────────────────────────
// No auth-gating in the provider — Firestore SDK handles auth tokens internally.
// Auth-gating here caused the stream to restart on every auth state emission,
// which made the UI briefly show stale/null data (the "revert" bug).

final facultyListProvider = StreamProvider<List<Faculty>>((ref) {
  return ref.watch(facultyRepositoryProvider).getFaculties();
});

final facultyListOnceProvider = FutureProvider<List<Faculty>>((ref) async {
  return ref.read(facultyRepositoryProvider).getFacultiesOnce();
});

// ── Single faculty doc stream — the correct way to watch one faculty ──────────
// Streams a single Firestore document by ID. This never restarts, never reverts.
// Use this everywhere you need live status for one faculty member.
final facultyByIdStreamProvider =
    StreamProvider.family<Faculty?, String>((ref, id) {
  return ref.watch(facultyRepositoryProvider).getFacultyStream(id);
});

final facultyByIdProvider = FutureProvider.family<Faculty?, String>((ref, id) {
  return ref.read(facultyRepositoryProvider).getFacultyById(id);
});

// ── One-time email lookup — used ONCE at login to resolve the Firestore doc ID.
// After resolving, always use facultyByIdStreamProvider(id) for live data.
final facultyByEmailProvider = FutureProvider.family<Faculty?, String>((ref, email) async {
  final list = await ref.read(facultyRepositoryProvider).getFacultiesOnce();
  try {
    return list.firstWhere(
      (f) => f.email.toLowerCase() == email.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
});

// ── Filter / search ───────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedDepartmentProvider = StateProvider<String?>((ref) => null);

final filteredFacultyProvider = Provider<AsyncValue<List<Faculty>>>((ref) {
  final facultiesAsync = ref.watch(facultyListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final dept  = ref.watch(selectedDepartmentProvider);
  return facultiesAsync.whenData((list) => list.where((f) {
    final matchSearch = query.isEmpty
        || f.name.toLowerCase().contains(query)
        || f.department.toLowerCase().contains(query)
        || f.building.toLowerCase().contains(query)
        || (f.specialization?.toLowerCase().contains(query) ?? false);
    final matchDept = dept == null || f.department == dept;
    return matchSearch && matchDept;
  }).toList());
});

final availableFacultyProvider = Provider<AsyncValue<List<Faculty>>>((ref) {
  return ref.watch(facultyListProvider).whenData(
    (list) => list.where((f) => f.status == FacultyStatus.available).toList(),
  );
});

final departmentsProvider = Provider<List<String>>((ref) {
  return ref.watch(facultyListProvider).maybeWhen(
    data: (list) {
      final depts = list.map((f) => f.department).toSet().toList()..sort();
      return depts;
    },
    orElse: () => [],
  );
});

// ── Faculty Notifier ──────────────────────────────────────────────────────────

class FacultyNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreFacultyRepository _repo;
  FacultyNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> updateStatus(
    String id,
    FacultyStatus status, {
    String? activeContext,
    DateTime? expectedReturnAt,
    DateTime? manualOverrideUntil,
    String? customStatusText,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateFacultyStatus(
        id, status,
        activeContext: activeContext,
        expectedReturnAt: expectedReturnAt,
        manualOverrideUntil: manualOverrideUntil,
        customStatusText: customStatusText,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFaculty(Faculty faculty) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addFaculty(faculty);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> updateFaculty(Faculty faculty) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateFaculty(faculty);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> deleteFaculty(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteFaculty(id);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }
}

final facultyNotifierProvider =
    StateNotifierProvider<FacultyNotifier, AsyncValue<void>>((ref) {
  return FacultyNotifier(ref.watch(facultyRepositoryProvider));
});
