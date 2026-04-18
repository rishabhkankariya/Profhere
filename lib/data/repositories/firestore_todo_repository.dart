import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/todo.dart';

class FirestoreTodoRepository {
  static const _uuid = Uuid();
  final _col = FirebaseFirestore.instance.collection('todos');

  TodoItem _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TodoItem(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      subject: d['subject'] as String?,
      notes: d['notes'] as String?,
      isDone: d['isDone'] as bool? ?? false,
      priority: TodoPriority.values[(d['priority'] as int? ?? 1)
          .clamp(0, TodoPriority.values.length - 1)],
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Stream<List<TodoItem>> watchByUser(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .handleError((_) {})
        .map((snap) {
          final list = snap.docs.map(_fromDoc).toList();
          list.sort((a, b) {
            // Undone first, then by due date, then by priority
            if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
            if (a.dueDate != null && b.dueDate != null) {
              return a.dueDate!.compareTo(b.dueDate!);
            }
            if (a.dueDate != null) return -1;
            if (b.dueDate != null) return 1;
            return b.priority.index.compareTo(a.priority.index);
          });
          return list;
        });
  }

  Future<void> add(TodoItem item) async {
    final id = item.id.isEmpty ? _uuid.v4() : item.id;
    await _col.doc(id).set({
      'userId': item.userId,
      'title': item.title,
      'subject': item.subject,
      'notes': item.notes,
      'isDone': item.isDone,
      'priority': item.priority.index,
      'dueDate': item.dueDate != null ? Timestamp.fromDate(item.dueDate!) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });
  }

  Future<void> toggle(String id, bool isDone) async {
    await _col.doc(id).update({
      'isDone': isDone,
      'completedAt': isDone ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> update(TodoItem item) async {
    await _col.doc(item.id).update({
      'title': item.title,
      'subject': item.subject,
      'notes': item.notes,
      'priority': item.priority.index,
      'dueDate': item.dueDate != null ? Timestamp.fromDate(item.dueDate!) : null,
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
