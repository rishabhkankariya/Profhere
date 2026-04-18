import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_event_repository.dart';
import '../../domain/entities/event.dart';

final eventRepositoryProvider = Provider((_) => FirestoreEventRepository());

final eventsProvider = StreamProvider<List<CollegeEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAll(approvedOnly: true);
});

final pendingEventsProvider = StreamProvider<List<CollegeEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).watchPending();
});

class EventNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreEventRepository _repo;
  EventNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> add(CollegeEvent event, {bool autoApprove = false}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.add(event, autoApprove: autoApprove);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> approve(String id) async {
    try { await _repo.approve(id); } catch (_) {}
  }

  Future<void> update(CollegeEvent event) async {
    state = const AsyncValue.loading();
    try {
      await _repo.update(event);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> delete(String id) async {
    try { await _repo.delete(id); } catch (_) {}
  }
}

final eventNotifierProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<void>>(
        (ref) => EventNotifier(ref.watch(eventRepositoryProvider)));
