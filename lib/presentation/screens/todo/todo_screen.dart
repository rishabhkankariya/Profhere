import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/todo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Tasks'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Search tasks…',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: todosAsync.when(
            data: (all) {
              final filtered = _search.isEmpty
                  ? all
                  : all.where((t) =>
                      t.title.toLowerCase().contains(_search) ||
                      (t.subject?.toLowerCase().contains(_search) ?? false) ||
                      (t.notes?.toLowerCase().contains(_search) ?? false)).toList();

              final pending   = filtered.where((t) => !t.isDone).toList();
              final completed = filtered.where((t) => t.isDone).toList();

              return TabBarView(
                controller: _tabs,
                children: [
                  _TodoList(items: pending,   emptyMsg: 'No pending tasks', onTap: _showEditSheet),
                  _TodoList(items: completed, emptyMsg: 'No completed tasks yet', onTap: _showEditSheet),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    _showTodoSheet(context, null);
  }

  void _showEditSheet(BuildContext context, TodoItem item) {
    _showTodoSheet(context, item);
  }

  void _showTodoSheet(BuildContext context, TodoItem? existing) {
    final isEdit = existing != null;
    final titleCtrl   = TextEditingController(text: existing?.title ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final notesCtrl   = TextEditingController(text: existing?.notes ?? '');
    TodoPriority priority = existing?.priority ?? TodoPriority.medium;
    DateTime? dueDate = existing?.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Text(isEdit ? 'Edit Task' : 'New Task',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      onPressed: () {
                        ref.read(todoNotifierProvider.notifier).delete(existing.id);
                        Navigator.pop(ctx);
                      },
                    ),
                ]),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: titleCtrl,
                  autofocus: !isEdit,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Task title *',
                    prefixIcon: Icon(Icons.task_alt_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 12),

                // Subject
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject / Course',
                    hintText: 'e.g. Data Structures, Physics',
                    prefixIcon: Icon(Icons.book_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Additional details…',
                    prefixIcon: Icon(Icons.notes_rounded, size: 18),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Priority
                const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Row(children: TodoPriority.values.map((p) {
                  final colors = [AppColors.success, AppColors.warning, AppColors.error];
                  final labels = ['Low', 'Medium', 'High'];
                  final active = priority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ss(() => priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: p.index < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? colors[p.index].withValues(alpha: 0.12) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active ? colors[p.index] : AppColors.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Column(children: [
                          Icon(Icons.flag_rounded, size: 16, color: active ? colors[p.index] : AppColors.textMuted),
                          const SizedBox(height: 4),
                          Text(labels[p.index], style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: active ? colors[p.index] : AppColors.textMuted,
                          )),
                        ]),
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),

                // Due date
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) ss(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: dueDate != null ? AppColors.primaryLight : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dueDate != null ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 16,
                          color: dueDate != null ? AppColors.primary : AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        dueDate != null
                            ? 'Due: ${_fmtDate(dueDate!)}'
                            : 'Set due date (optional)',
                        style: TextStyle(
                          fontSize: 14,
                          color: dueDate != null ? AppColors.primary : AppColors.textMuted,
                          fontWeight: dueDate != null ? FontWeight.w600 : FontWeight.w400,
                        ),
                      )),
                      if (dueDate != null)
                        GestureDetector(
                          onTap: () => ss(() => dueDate = null),
                          child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Save
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final uid = ref.read(authNotifierProvider).user?.id ?? '';
                    if (isEdit) {
                      await ref.read(todoNotifierProvider.notifier).update(
                        existing.copyWith(
                          title: titleCtrl.text.trim(),
                          subject: subjectCtrl.text.trim().isEmpty ? null : subjectCtrl.text.trim(),
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          priority: priority,
                          dueDate: dueDate,
                        ),
                      );
                    } else {
                      await ref.read(todoNotifierProvider.notifier).add(
                        TodoItem(
                          id: const Uuid().v4(),
                          userId: uid,
                          title: titleCtrl.text.trim(),
                          subject: subjectCtrl.text.trim().isEmpty ? null : subjectCtrl.text.trim(),
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          priority: priority,
                          dueDate: dueDate,
                          createdAt: DateTime.now(),
                        ),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Add Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}, ${d.year}';
  }
}

// ─── Todo list widget ─────────────────────────────────────────────────────────

class _TodoList extends ConsumerWidget {
  final List<TodoItem> items;
  final String emptyMsg;
  final void Function(BuildContext, TodoItem) onTap;
  const _TodoList({required this.items, required this.emptyMsg, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline_rounded, size: 52, color: AppColors.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(emptyMsg, style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
      ]));
    }

    // Group by subject
    final grouped = <String, List<TodoItem>>{};
    for (final t in items) {
      final key = t.subject ?? 'General';
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: grouped.entries.map((entry) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Row(children: [
              Container(width: 4, height: 14,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(entry.key, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textMuted, letterSpacing: 0.3)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                child: Text('${entry.value.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ]),
          ),
          ...entry.value.map((t) => _TodoCard(item: t, onTap: () => onTap(context, t))),
        ],
      )).toList(),
    );
  }
}

class _TodoCard extends ConsumerWidget {
  final TodoItem item;
  final VoidCallback onTap;
  const _TodoCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColors = [AppColors.success, AppColors.warning, AppColors.error];
    final pColor = priorityColors[item.priority.index];
    final isOverdue = item.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isDone
              ? AppColors.border
              : isOverdue
                  ? AppColors.error.withValues(alpha: 0.4)
                  : AppColors.border,
          width: isOverdue && !item.isDone ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            // Checkbox
            GestureDetector(
              onTap: () => ref.read(todoNotifierProvider.notifier)
                  .toggle(item.id, !item.isDone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: item.isDone ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: item.isDone ? AppColors.success : AppColors.border,
                    width: 2,
                  ),
                ),
                child: item.isDone
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: item.isDone ? AppColors.textMuted : AppColors.textPrimary,
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              if (item.notes != null) ...[
                const SizedBox(height: 2),
                Text(item.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (item.dueDate != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(
                    isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
                    size: 11,
                    color: isOverdue ? AppColors.error : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(item.dueDate!),
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue ? AppColors.error : AppColors.textMuted,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(4)),
                      child: const Text('OVERDUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.error)),
                    ),
                  ],
                ]),
              ],
            ])),

            // Priority dot
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: item.isDone ? AppColors.border : pColor,
                shape: BoxShape.circle,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}';
  }
}
