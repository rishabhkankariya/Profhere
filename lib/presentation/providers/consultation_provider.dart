import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_consultation_repository.dart';
import '../../domain/entities/consultation.dart';
import 'auth_provider.dart';

final consultationRepositoryProvider =
    Provider<FirestoreConsultationRepository>((ref) {
  return FirestoreConsultationRepository();
});

final consultationsByFacultyProvider =
    StreamProvider.family<List<Consultation>, String>((ref, facultyId) async* {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) { yield []; return; }
  yield* ref.watch(consultationRepositoryProvider).watchByFaculty(facultyId);
});

class ConsultationNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreConsultationRepository _repo;
  ConsultationNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<Consultation?> joinQueue({
    required String facultyId,
    required String studentId,
    required String studentName,
    required String purpose,
  }) async {
    state = const AsyncValue.loading();
    try {
      final alreadyInQueue = await _repo.hasActiveRequest(studentId, facultyId);
      if (alreadyInQueue) {
        state = AsyncValue.error(
            'You already have an active request for this faculty.', StackTrace.current);
        return null;
      }
      final c = await _repo.joinQueue(
        facultyId: facultyId,
        studentId: studentId,
        studentName: studentName,
        purpose: purpose,
      );
      state = const AsyncValue.data(null);
      return c;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateStatus(String id, ConsultationStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateStatus(id, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final consultationNotifierProvider =
    StateNotifierProvider<ConsultationNotifier, AsyncValue<void>>((ref) {
  return ConsultationNotifier(ref.watch(consultationRepositoryProvider));
});
