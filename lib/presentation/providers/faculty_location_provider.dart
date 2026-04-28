import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_faculty_location_repository.dart';
import '../../domain/entities/faculty_location.dart';
import '../../domain/repositories/faculty_location_repository.dart';

final facultyLocationRepositoryProvider =
    Provider<FacultyLocationRepository>((ref) {
  return FirestoreFacultyLocationRepository();
});

/// Stream faculty's real-time location
final facultyLocationProvider =
    StreamProvider.family<FacultyLocation?, String>((ref, facultyId) {
  return ref
      .watch(facultyLocationRepositoryProvider)
      .getFacultyLocation(facultyId);
});

/// Get last known location (one-time fetch)
final lastKnownLocationProvider =
    FutureProvider.family<FacultyLocation?, String>((ref, facultyId) {
  return ref
      .watch(facultyLocationRepositoryProvider)
      .getLastKnownLocation(facultyId);
});

/// Notifier for updating faculty location
class FacultyLocationNotifier extends StateNotifier<AsyncValue<void>> {
  final FacultyLocationRepository _repository;

  FacultyLocationNotifier(this._repository)
      : super(const AsyncValue.data(null));

  Future<void> updateLocation({
    required String facultyId,
    required String building,
    required String floor,
    String? zone,
    String? cabinId,
    required String nodeMcuIp,
    required bool isPresent,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateFacultyLocation(
          facultyId: facultyId,
          building: building,
          floor: floor,
          zone: zone,
          cabinId: cabinId,
          nodeMcuIp: nodeMcuIp,
          isPresent: isPresent,
        ));
  }

  Future<void> markAbsent(String facultyId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repository.markFacultyAbsent(facultyId));
  }
}

final facultyLocationNotifierProvider =
    StateNotifierProvider<FacultyLocationNotifier, AsyncValue<void>>((ref) {
  return FacultyLocationNotifier(
    ref.watch(facultyLocationRepositoryProvider),
  );
});
