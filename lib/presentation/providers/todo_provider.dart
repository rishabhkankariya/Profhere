import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_todo_repository.dart';
import '../../domain/entities/todo.dart';
import 'auth_provider.dart';

final todoRepositoryProvider = Provider((_) => FirestoreTodoRepository());

final todoListProvider = StreamProvider<List<TodoItem>>((ref) {
  final uid = ref.watch(authNotifierProvider).user?.id ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(todoRepositoryProvider).watchByUser(uid);
});

class TodoNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreTodoRepository _repo;
  TodoNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> add(TodoItem item) async {
    state = const AsyncValue.loading();
    try {
      await _repo.add(item);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> toggle(String id, bool isDone) async {
    try { await _repo.toggle(id, isDone); } catch (_) {}
  }

  Future<void> update(TodoItem item) async {
    state = const AsyncValue.loading();
    try {
      await _repo.update(item);
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> delete(String id) async {
    try { await _repo.delete(id); } catch (_) {}
  }
}

final todoNotifierProvider =
    StateNotifierProvider<TodoNotifier, AsyncValue<void>>(
        (ref) => TodoNotifier(ref.watch(todoRepositoryProvider)));
