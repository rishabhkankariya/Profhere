import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_faculty_repository.dart';
import '../../domain/entities/faculty.dart';
import 'auth_provider.dart';

final facultyRepositoryProvider = Provider<FirestoreFacultyRepository>((ref) {
  return FirestoreFacultyRepository();
});

// ── Faculty list stream ───────────────────────────────────────────────────────
// Does NOT watch authStateProvider — Firestore SDK handles auth internally.
// Watching auth state here would restart the stream on every auth emission.

final facultyListProvider = StreamProvider<List<Faculty>>((ref) {
  return ref.watch(facultyRepositoryProvider).getFaculties();
});

final facultyListOnceProvider = FutureProvider<List<Faculty>>((ref) async {
  return ref.watch(facultyRepositoryProvider).getFacultiesOnce();
});

final facultyByIdProvider = FutureProvider.family<Faculty?, String>((ref, id) async {
  return ref.watch(facultyRepositoryProvider).getFacultyById(id);
});

/// Live stream of a single faculty document by Firestore doc ID.
/// Most stable approach — directly watches one document, never restarts.
final facultyByIdStreamProvider =
    StreamProvider.family<Faculty?, String>((ref, id) {
  return ref.watch(facultyRepositoryProvider).getFacultyStream(id);
});

/// One-time lookup of faculty doc ID by email.
/// Used only once at login to resolve the Firestore doc ID.
final facultyByEmailProvider = FutureProvider.family<Faculty?, String>((ref, email) async {
  final list = await ref.read(facultyRepositoryProvider).getFacultiesOnce();
  try {
    return list.firstWhere((f) => f.email.toLowerCase() == email.toLowerCase());
  } catch (_) {
    return null;
  }
});

// ── Filter / search providers ─────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedDepartmentProvider = StateProvider<String?>((ref) => null);

final filteredFacultyProvider = Provider<AsyncValue<List<Faculty>>>((ref) {
  final facultiesAsync = ref.watch(facultyListProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final selectedDepartment = ref.watch(selectedDepartmentProvider);
  return facultiesAsync.whenData((faculties) {
    return faculties.where((f) {
      final matchesSearch = searchQuery.isEmpty ||
          f.name.toLowerCase().contains(searchQuery) ||
          f.department.toLowerCase().contains(searchQuery) ||
          f.building.toLowerCase().contains(searchQuery) ||
          (f.specialization?.toLowerCase().contains(searchQuery) ?? false);
      final matchesDepartment = selectedDepartment == null || f.department == selectedDepartment;
      return matchesSearch && matchesDepartment;
    }).toList();
  });
});

final availableFacultyProvider = Provider<AsyncValue<List<Faculty>>>((ref) {
  return ref.watch(facultyListProvider).whenData(
    (faculties) => faculties.where((f) => f.status == FacultyStatus.available).toList(),
  );
});

final departmentsProvider = Provider<List<String>>((ref) {
  return ref.watch(facultyListProvider).maybeWhen(
    data: (faculties) {
      final departments = faculties.map((f) => f.department).toSet().toList();
      departments.sort();
      return departments;
    },
    orElse: () => [],
  );
});

// ── Faculty Notifier ──────────────────────────────────────────────────────────

class FacultyNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreFacultyRepository _repository;
  FacultyNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> updateStatus(String id, FacultyStatus status, {
    String? activeContext, DateTime? expectedReturnAt, DateTime? manualOverrideUntil,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateFacultyStatus(id, status,
          activeContext: activeContext,
          expectedReturnAt: expectedReturnAt,
          manualOverrideUntil: manualOverrideUntil);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> addFaculty(Faculty faculty) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addFaculty(faculty);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> updateFaculty(Faculty faculty) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateFaculty(faculty);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> deleteFaculty(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteFaculty(id);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }
}

final facultyNotifierProvider =
    StateNotifierProvider<FacultyNotifier, AsyncValue<void>>((ref) {
  return FacultyNotifier(ref.watch(facultyRepositoryProvider));
});
