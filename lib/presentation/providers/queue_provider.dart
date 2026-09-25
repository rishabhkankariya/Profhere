import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/queue_utils.dart';
import '../../data/repositories/queue_repository.dart';
import '../../data/services/queue_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/queue_entry.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

final queueServiceProvider = Provider<QueueService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return QueueService(client);
});

final queueRepositoryProvider = Provider<QueueRepository?>((ref) {
  final service = ref.watch(queueServiceProvider);
  if (service == null) {
    return null;
  }

  return QueueRepository(service);
});

final facultyQueueProvider = StreamProvider.family<List<QueueEntry>, String>((
  ref,
  facultyId,
) async* {
  final repository = ref.watch(queueRepositoryProvider);
  if (repository == null) {
    yield const <QueueEntry>[];
    return;
  }

  yield* repository.watchQueueForFaculty(facultyId);
});

final queueSummaryProvider = Provider.family<AsyncValue<QueueSummary>, String>((
  ref,
  facultyId,
) {
  final queueEntries = ref.watch(facultyQueueProvider(facultyId));
  return queueEntries.whenData((entries) {
    final calledEntries =
        entries
            .where((entry) => entry.status == QueueEntryStatus.called)
            .toList()
          ..sort((a, b) => b.position.compareTo(a.position));

    return QueueSummary(
      totalEntries: entries.length,
      waitingCount: QueueUtils.waitingCount(entries),
      nowServing: calledEntries.isEmpty ? null : calledEntries.first,
    );
  });
});

final studentQueueProvider = StreamProvider<List<QueueEntry>>((ref) async* {
  final currentUser = await ref.watch(authStateProvider.future);
  final repository = ref.watch(queueRepositoryProvider);

  if (currentUser == null || repository == null) {
    yield const <QueueEntry>[];
    return;
  }

  yield* repository.watchQueueForStudent(currentUser.id);
});

final queueControllerProvider = Provider<QueueController>((ref) {
  return QueueController(ref);
});

class QueueController {
  QueueController(this._ref);

  final Ref _ref;

  Future<void> joinQueue({required String facultyId}) async {
    final currentUser = await _ref.read(authStateProvider.future);
    final repository = _ref.read(queueRepositoryProvider);

    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }

    if (currentUser == null || currentUser.role != UserRole.student) {
      throw StateError('Only student users can join a queue.');
    }

    await repository.joinQueue(facultyId: facultyId, studentId: currentUser.id);

    _ref.invalidate(facultyQueueProvider(facultyId));
    _ref.invalidate(studentQueueProvider);
  }

  void refreshQueue(String facultyId) {
    _ref.invalidate(facultyQueueProvider(facultyId));
  }

  Future<void> updateQueueStatus({
    required String facultyId,
    required String queueEntryId,
    required QueueEntryStatus status,
  }) async {
    final currentUser = await _ref.read(authStateProvider.future);
    final repository = _ref.read(queueRepositoryProvider);

    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }

    if (currentUser == null || currentUser.role != UserRole.faculty) {
      throw StateError('Only faculty users can update queue entries.');
    }

    await repository.updateQueueStatus(
      queueEntryId: queueEntryId,
      status: status,
    );

    _ref.invalidate(facultyQueueProvider(facultyId));
    _ref.invalidate(queueSummaryProvider(facultyId));
    _ref.invalidate(studentQueueProvider);
  }

  Future<QueueEntry?> callNextStudent(String facultyId) async {
    final currentUser = await _ref.read(authStateProvider.future);
    final repository = _ref.read(queueRepositoryProvider);

    if (repository == null) {
      throw StateError('Supabase is not configured.');
    }

    if (currentUser == null || currentUser.role != UserRole.faculty) {
      throw StateError('Only faculty users can call the next student.');
    }

    final updatedEntry = await repository.callNextStudent(facultyId);
    _ref.invalidate(facultyQueueProvider(facultyId));
    _ref.invalidate(queueSummaryProvider(facultyId));
    _ref.invalidate(studentQueueProvider);
    return updatedEntry;
  }
}

class QueueSummary {
  const QueueSummary({
    required this.totalEntries,
    required this.waitingCount,
    required this.nowServing,
  });

  final int totalEntries;
  final int waitingCount;
  final QueueEntry? nowServing;
}
