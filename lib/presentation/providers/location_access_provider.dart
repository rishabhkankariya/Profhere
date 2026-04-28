import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_location_access_repository.dart';
import '../../domain/entities/location_access.dart';
import '../../domain/repositories/location_access_repository.dart';

final locationAccessRepositoryProvider =
    Provider<LocationAccessRepository>((ref) {
  return FirestoreLocationAccessRepository();
});

// ── Faculty: Get all access requests (pending, approved, rejected, revoked) ──
final accessRequestsForFacultyProvider =
    StreamProvider.family<List<LocationAccess>, String>((ref, facultyId) {
  return ref
      .watch(locationAccessRepositoryProvider)
      .getAccessRequestsForFaculty(facultyId);
});

// ── Faculty: Get only pending requests ──
final pendingAccessRequestsProvider =
    StreamProvider.family<List<LocationAccess>, String>((ref, facultyId) {
  return ref
      .watch(locationAccessRepositoryProvider)
      .getAccessRequestsForFaculty(facultyId)
      .map((requests) => requests.where((r) => r.isPending).toList());
});

// ── Faculty: Get only approved accesses ──
final approvedAccessesForFacultyProvider =
    StreamProvider.family<List<LocationAccess>, String>((ref, facultyId) {
  return ref
      .watch(locationAccessRepositoryProvider)
      .getApprovedAccessesForFaculty(facultyId);
});

// ── Student: Get all access requests from this student ──
final accessRequestsFromStudentProvider =
    StreamProvider.family<List<LocationAccess>, String>((ref, studentId) {
  return ref
      .watch(locationAccessRepositoryProvider)
      .getAccessRequestsFromStudent(studentId);
});

// ── Admin: Get all pending accesses across all faculty ──
final allPendingAccessesProvider =
    StreamProvider<List<LocationAccess>>((ref) {
  return ref
      .watch(locationAccessRepositoryProvider)
      .getAllPendingAccesses();
});

// ── Admin: Get all accesses for a specific faculty ──
final allAccessesForFacultyProvider =
    StreamProvider.family<List<LocationAccess>, String>((ref, facultyId) {
  return ref
      .watch(locationAccessRepositoryProvider)
      .getAllAccessesForFaculty(facultyId);
});

// ── Check if student has approved access to faculty ──
final hasApprovedAccessProvider = FutureProvider.family<bool,
    ({String facultyId, String studentId})>((ref, params) async {
  return ref
      .watch(locationAccessRepositoryProvider)
      .hasApprovedAccess(
        facultyId: params.facultyId,
        studentId: params.studentId,
      );
});

// ── Get approved access record (with NodeMCU IP) ──
final approvedAccessProvider = FutureProvider.family<LocationAccess?,
    ({String facultyId, String studentId})>((ref, params) async {
  return ref
      .watch(locationAccessRepositoryProvider)
      .getApprovedAccess(
        facultyId: params.facultyId,
        studentId: params.studentId,
      );
});

// ── Notifier for location access mutations ──
class LocationAccessNotifier extends StateNotifier<AsyncValue<void>> {
  final LocationAccessRepository _repository;

  LocationAccessNotifier(this._repository)
      : super(const AsyncValue.data(null));

  Future<void> requestLocationAccess({
    required String facultyId,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _repository.requestLocationAccess(
          facultyId: facultyId,
          studentId: studentId,
          studentName: studentName,
          studentEmail: studentEmail,
        ));
  }

  Future<void> approveLocationAccess({
    required String accessId,
    required String nodeMcuIpAddress,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _repository.approveLocationAccess(
          accessId: accessId,
          nodeMcuIpAddress: nodeMcuIpAddress,
        ));
  }

  Future<void> rejectLocationAccess({
    required String accessId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _repository.rejectLocationAccess(
          accessId: accessId,
          reason: reason,
        ));
  }

  Future<void> revokeLocationAccess({
    required String accessId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _repository.revokeLocationAccess(
          accessId: accessId,
          reason: reason,
        ));
  }
}

final locationAccessNotifierProvider =
    StateNotifierProvider<LocationAccessNotifier, AsyncValue<void>>((ref) {
  return LocationAccessNotifier(
    ref.watch(locationAccessRepositoryProvider),
  );
});
