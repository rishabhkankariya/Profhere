import 'package:equatable/equatable.dart';

enum TodoPriority { low, medium, high }

class TodoItem extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? subject;
  final String? notes;
  final bool isDone;
  final TodoPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TodoItem({
    required this.id,
    required this.userId,
    required this.title,
    this.subject,
    this.notes,
    this.isDone = false,
    this.priority = TodoPriority.medium,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
  });

  bool get isOverdue =>
      !isDone && dueDate != null && dueDate!.isBefore(DateTime.now());

  TodoItem copyWith({
    String? id, String? userId, String? title, String? subject,
    String? notes, bool? isDone, TodoPriority? priority,
    DateTime? dueDate, DateTime? createdAt, DateTime? completedAt,
  }) => TodoItem(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    subject: subject ?? this.subject,
    notes: notes ?? this.notes,
    isDone: isDone ?? this.isDone,
    priority: priority ?? this.priority,
    dueDate: dueDate ?? this.dueDate,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt ?? this.completedAt,
  );

  @override
  List<Object?> get props => [id, userId, title, subject, notes, isDone,
      priority, dueDate, createdAt, completedAt];
}
