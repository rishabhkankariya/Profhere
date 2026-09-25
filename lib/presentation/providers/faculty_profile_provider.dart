import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/faculty.dart';
import 'auth_provider.dart';
import 'faculty_provider.dart';

final currentFacultyProfileProvider = FutureProvider<Faculty?>((ref) async {
  final currentUser = await ref.watch(authStateProvider.future);
  final repository = ref.watch(facultyRepositoryProvider);

  if (currentUser == null ||
      (currentUser.role != UserRole.faculty &&
          currentUser.role != UserRole.admin) ||
      repository == null) {
    return null;
  }

  return repository.fetchFacultyByUserId(currentUser.id);
});

final facultyProfileControllerProvider = Provider<FacultyProfileController>((
  ref,
) {
  return FacultyProfileController(ref);
});

class FacultyProfileController {
  FacultyProfileController(this._ref);

  final Ref _ref;

  Future<void> updateProfile({
    required String facultyId,
    required String name,
    required String cabin,
  }) async {
    final repository = _ref.read(facultyRepositoryProvider);
    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }

    await repository.updateFacultyProfile(
      facultyId: facultyId,
      name: name,
      cabin: cabin,
    );

    _ref.invalidate(currentFacultyProfileProvider);
    _ref.invalidate(facultyListProvider);
  }

  Future<void> updateStatus({
    required String facultyId,
    required String status,
  }) async {
    final repository = _ref.read(facultyRepositoryProvider);
    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }

    await repository.updateFacultyStatus(facultyId: facultyId, status: status);

    _ref.invalidate(currentFacultyProfileProvider);
    _ref.invalidate(facultyListProvider);
  }
}
