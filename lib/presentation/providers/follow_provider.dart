import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/follow_repository.dart';
import '../../data/services/follow_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/follow_entry.dart';
import 'auth_provider.dart';
import 'faculty_provider.dart';
import 'supabase_provider.dart';

final followServiceProvider = Provider<FollowService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return FollowService(client);
});

final followRepositoryProvider = Provider<FollowRepository?>((ref) {
  final service = ref.watch(followServiceProvider);
  if (service == null) {
    return null;
  }

  return FollowRepository(service);
});

final followEntriesProvider = StreamProvider<List<FollowEntry>>((ref) async* {
  final currentUser = await ref.watch(authStateProvider.future);
  final repository = ref.watch(followRepositoryProvider);

  if (currentUser == null || repository == null) {
    yield const <FollowEntry>[];
    return;
  }

  yield* repository.watchFollowEntries(currentUser.id);
});

final followedFacultyProvider = Provider<AsyncValue<List<Faculty>>>((ref) {
  final followEntries = ref.watch(followEntriesProvider);
  final facultyList = ref.watch(facultyListProvider);

  if (followEntries.hasError) {
    return AsyncError(
      followEntries.error!,
      followEntries.stackTrace ?? StackTrace.current,
    );
  }

  if (facultyList.hasError) {
    return AsyncError(
      facultyList.error!,
      facultyList.stackTrace ?? StackTrace.current,
    );
  }

  if (!followEntries.hasValue || !facultyList.hasValue) {
    return const AsyncLoading();
  }

  final entries = followEntries.requireValue;
  final faculty = facultyList.requireValue;

  return AsyncData(
    faculty
        .where((item) => entries.any((entry) => entry.facultyId == item.id))
        .toList(),
  );
});

final isFollowingFacultyProvider = Provider.family<AsyncValue<bool>, String>((
  ref,
  facultyId,
) {
  final followEntries = ref.watch(followEntriesProvider);
  return followEntries.whenData(
    (entries) => entries.any((entry) => entry.facultyId == facultyId),
  );
});

final followControllerProvider = Provider<FollowController>((ref) {
  return FollowController(ref);
});

class FollowController {
  FollowController(this._ref);

  final Ref _ref;

  Future<void> followFaculty(String facultyId) async {
    final currentUser = await _ref.read(authStateProvider.future);
    final repository = _ref.read(followRepositoryProvider);

    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }

    if (currentUser == null || currentUser.role != UserRole.student) {
      throw StateError('Only student users can follow faculty.');
    }

    await repository.followFaculty(
      studentId: currentUser.id,
      facultyId: facultyId,
    );

    _invalidateFollowState(facultyId);
  }

  Future<void> unfollowFaculty(String facultyId) async {
    final currentUser = await _ref.read(authStateProvider.future);
    final repository = _ref.read(followRepositoryProvider);

    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }

    if (currentUser == null || currentUser.role != UserRole.student) {
      throw StateError('Only student users can unfollow faculty.');
    }

    await repository.unfollowFaculty(
      studentId: currentUser.id,
      facultyId: facultyId,
    );

    _invalidateFollowState(facultyId);
  }

  Future<void> toggleFollow(String facultyId) async {
    final entries = await _ref.read(followEntriesProvider.future);
    final isFollowing = entries.any((entry) => entry.facultyId == facultyId);

    if (isFollowing) {
      await unfollowFaculty(facultyId);
      return;
    }

    await followFaculty(facultyId);
  }

  void _invalidateFollowState(String facultyId) {
    _ref.invalidate(followEntriesProvider);
    _ref.invalidate(followedFacultyProvider);
    _ref.invalidate(isFollowingFacultyProvider(facultyId));
  }
}
