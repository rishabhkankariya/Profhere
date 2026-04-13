import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/faculty.dart';
import '../../../domain/entities/consultation.dart';
import '../../../domain/entities/academic.dart';
import '../../providers/auth_provider.dart';
import '../../providers/faculty_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/faculty_avatar.dart';
import '../../../core/services/widget_service.dart';

class FacultyDashboardScreen extends ConsumerStatefulWidget {
  const FacultyDashboardScreen({super.key});
  @override
  ConsumerState<FacultyDashboardScreen> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends ConsumerState<FacultyDashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final facultyId = user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello, ${user?.name.split(' ').first ?? 'Faculty'} 👋',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Text('Faculty Dashboard', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Column(children: [
        _buildTabBar(),
        Expanded(child: IndexedStack(index: _tab, children: [
          _OverviewTab(facultyId: facultyId),
          _QueueTab(facultyId: facultyId),
          _ScheduleTab(facultyId: facultyId),
        ])),
      ]),
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Overview', 'Queue', 'Schedule'];
    return Container(
      color: AppColors.surface,
      child: Row(children: List.generate(tabs.length, (i) {
        final active = _tab == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: active ? AppColors.primary : Colors.transparent,
                  width: 2,
                )),
              ),
              child: Text(tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textMuted,
                  )),
            ),
          ),
        );
      })),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final String? facultyId;
  const _OverviewTab({this.facultyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Watch the STREAM — equivalent to WebSocket: UI rebuilds instantly on any change
    // This is the key fix: facultyListProvider is a StreamProvider backed by Hive stream
    // When admin or faculty updates status → Hive emits → stream fires → UI rebuilds
    final allFacultiesAsync = ref.watch(facultyListProvider);

    // Derive the current faculty's live data from the stream (not a one-shot Future)
    final liveFaculty = allFacultiesAsync.whenData(
      (list) => facultyId != null
          ? list.where((f) => f.id == facultyId).firstOrNull
          : null,
    ).value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Hero card — now driven by stream, updates instantly
        _StatusCard(faculty: liveFaculty, facultyId: facultyId, ref: ref, context: context),
        const SizedBox(height: 12),
        _buildQuickActions(context, ref, facultyId, liveFaculty?.status),
        const SizedBox(height: 12),
        _buildQueueSummary(ref, facultyId),
      ]),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, String? id, FacultyStatus? currentStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FacultyStatus.available, FacultyStatus.busy, FacultyStatus.inLecture,
          FacultyStatus.meeting, FacultyStatus.away,
        ].map((s) => _StatusChip(
          status: s,
          isActive: currentStatus == s,
          onTap: () {
            if (id == null) return;
            // ✅ Future — equivalent to Promise: fire-and-forget async write
            ref.read(facultyNotifierProvider.notifier).updateStatus(id, s);
            // Sync home screen widget
            WidgetService.updateStatus(s);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Status set to ${s.label}'),
              backgroundColor: s.color,
            ));
          },
        )).toList()),
      ]),
    );
  }

  Widget _buildQueueSummary(WidgetRef ref, String? id) {
    if (id == null) return const SizedBox.shrink();
    final qAsync = ref.watch(consultationsByFacultyProvider(id));
    return qAsync.when(
      data: (list) {
        final waiting    = list.where((c) => c.status == ConsultationStatus.pending).length;
        final inProgress = list.where((c) => c.status == ConsultationStatus.inProgress).length;
        return Row(children: [
          Expanded(child: _SummaryTile(label: 'Waiting',     value: '$waiting',    color: AppColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryTile(label: 'In Progress', value: '$inProgress', color: AppColors.info)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryTile(label: 'Total Today', value: '${list.length}', color: AppColors.primary)),
        ]);
      },
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Faculty? faculty;
  final String? facultyId;
  final WidgetRef ref;
  final BuildContext context;
  const _StatusCard({this.faculty, this.facultyId, required this.ref, required this.context});

  /// Returns a gradient based on the current status color — darker shade to lighter
  LinearGradient _gradientForStatus(FacultyStatus status) {
    final base  = status.color;
    final light = Color.lerp(base, Colors.white, 0.25) ?? base;
    final dark  = Color.lerp(base, Colors.black, 0.15) ?? base;
    return LinearGradient(
      colors: [dark, light],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = faculty?.status ?? FacultyStatus.available;
    final gradient = _gradientForStatus(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: status.color.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        )],
      ),
      child: Row(children: [
        // Tappable avatar with upload overlay
        GestureDetector(
          onTap: facultyId != null
              ? () => _pickAvatar(context)
              : null,
          child: Stack(children: [
            FacultyAvatar(
              avatarBase64: faculty?.avatarUrl,
              initials: faculty?.initials ?? '?',
              size: 56,
              borderRadius: 16,
            ),
            if (facultyId != null)
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 11, color: AppColors.primary),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Current Status', style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(status.label.toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
          if (faculty?.activeContext != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(faculty!.activeContext!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ),
        ])),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(status.icon, color: Colors.white, size: 22),
        ),
      ]),
    );
  }

  void _pickAvatar(BuildContext context) {
    if (facultyId == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Profile Photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 20)),
            title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(avatarNotifierProvider.notifier).pickAndUpload(facultyId!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Profile photo updated'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
          ),
          if (faculty?.avatarUrl != null && faculty!.avatarUrl!.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20)),
              title: const Text('Remove photo', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(avatarNotifierProvider.notifier).removeAvatar(facultyId!);
              },
            ),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final FacultyStatus status;
  final bool isActive;
  final VoidCallback onTap;
  const _StatusChip({required this.status, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? status.color : status.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: status.color.withValues(alpha: isActive ? 1.0 : 0.3),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: status.color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(status.icon, size: 14, color: isActive ? Colors.white : status.color),
          const SizedBox(width: 6),
          Text(status.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : status.color,
              )),
          if (isActive) ...[
            const SizedBox(width: 4),
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ],
        ]),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }
}

// ─── Queue Tab ────────────────────────────────────────────────────────────────

class _QueueTab extends ConsumerWidget {
  final String? facultyId;
  const _QueueTab({this.facultyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (facultyId == null) return const Center(child: Text('No faculty profile linked'));
    final qAsync = ref.watch(consultationsByFacultyProvider(facultyId!));

    return qAsync.when(
      data: (list) {
        final active = list.where((c) => c.status == ConsultationStatus.pending || c.status == ConsultationStatus.inProgress).toList();
        if (active.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text('Queue is empty', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: active.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _QueueCard(
            consultation: active[i],
            position: i + 1,
            onCall: active[i].status == ConsultationStatus.pending
                ? () => ref.read(consultationNotifierProvider.notifier).updateStatus(active[i].id, ConsultationStatus.inProgress)
                : null,
            onDone: active[i].status == ConsultationStatus.inProgress
                ? () => ref.read(consultationNotifierProvider.notifier).updateStatus(active[i].id, ConsultationStatus.completed)
                : null,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final Consultation consultation;
  final int position;
  final VoidCallback? onCall, onDone;
  const _QueueCard({required this.consultation, required this.position, this.onCall, this.onDone});

  @override
  Widget build(BuildContext context) {
    final isActive = consultation.status == ConsultationStatus.inProgress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? AppColors.primary : AppColors.border, width: isActive ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryLight : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text('$position',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: isActive ? AppColors.primary : AppColors.textMuted))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(consultation.studentName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                child: const Text('IN PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ]),
          const SizedBox(height: 3),
          Text(consultation.purpose, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text('~${consultation.waitTimeMinutes} min wait',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        Column(children: [
          if (onCall != null)
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onCall,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14), textStyle: const TextStyle(fontSize: 12)),
                child: const Text('Call'),
              ),
            ),
          if (onDone != null)
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: onDone,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 12),
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                ),
                child: const Text('Done'),
              ),
            ),
        ]),
      ]),
    );
  }
}

// ─── Schedule Tab ─────────────────────────────────────────────────────────────

class _ScheduleTab extends ConsumerWidget {
  final String? facultyId;
  const _ScheduleTab({this.facultyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (facultyId == null) {
      return const Center(child: Text('No faculty profile linked'));
    }
    final ttAsync = ref.watch(facultyTimetableProvider(facultyId!));
    final today = DateTime.now().weekday;

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── FAB: Add new lecture ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntrySheet(context, ref, facultyId!, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Lecture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: ttAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 16),
                const Text('No lectures yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Tap + Add Lecture to get started', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ]),
            );
          }

          // Group by day
          final byDay = <int, List<TimetableEntry>>{};
          for (final e in entries) {
            byDay.putIfAbsent(e.dayOfWeek, () => []).add(e);
          }
          for (final list in byDay.values) {
            list.sort((a, b) => a.startTime.compareTo(b.startTime));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [1, 2, 3, 4, 5, 6, 7]
                .where((d) => byDay.containsKey(d))
                .map((d) {
              const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
              final isToday = d == today;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Day header
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Row(children: [
                    Text(dayNames[d - 1],
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: isToday ? AppColors.primary : AppColors.textMuted,
                          letterSpacing: 0.3,
                        )),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                        child: const Text('TODAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ]),
                ),
                ...byDay[d]!.map((e) => _EditableTimetableCard(
                  entry: e,
                  isToday: isToday,
                  onEdit: () => _showEntrySheet(context, ref, facultyId!, e),
                  onDelete: () => _confirmDelete(context, ref, e),
                )),
              ]);
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showEntrySheet(BuildContext context, WidgetRef ref, String facultyId, TimetableEntry? existing) {
    final isEdit = existing != null;
    final subjectCtrl = TextEditingController(text: existing?.subjectName ?? '');
    final roomCtrl    = TextEditingController(text: existing?.room ?? '');
    int selectedDay   = existing?.dayOfWeek ?? DateTime.now().weekday;
    TimeOfDay startTime = existing != null
        ? _parseTime(existing.startTime)
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = existing != null
        ? _parseTime(existing.endTime)
        : const TimeOfDay(hour: 11, minute: 0);

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Header
              Row(children: [
                Expanded(
                  child: Text(isEdit ? 'Edit Lecture' : 'Add Lecture',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                if (isEdit)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, ref, existing);
                    },
                  ),
              ]),
              const SizedBox(height: 20),

              // Subject name
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject / Lecture name',
                  prefixIcon: Icon(Icons.book_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 14),

              // Room
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room / Hall',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 20),

              // Day selector
              const Text('Day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: List.generate(7, (i) {
                final day = i + 1;
                final active = selectedDay == day;
                return GestureDetector(
                  onTap: () => setSheet(() => selectedDay = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.primary : AppColors.border),
                    ),
                    child: Center(child: Text(dayNames[i],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.textSecondary))),
                  ),
                );
              })),
              const SizedBox(height: 20),

              // Time pickers
              Row(children: [
                Expanded(child: _TimePicker(
                  label: 'Start time',
                  time: startTime,
                  onPick: () async {
                    final t = await showTimePicker(context: ctx, initialTime: startTime);
                    if (t != null) setSheet(() => startTime = t);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _TimePicker(
                  label: 'End time',
                  time: endTime,
                  onPick: () async {
                    final t = await showTimePicker(context: ctx, initialTime: endTime);
                    if (t != null) setSheet(() => endTime = t);
                  },
                )),
              ]),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: () {
                  if (subjectCtrl.text.trim().isEmpty || roomCtrl.text.trim().isEmpty) return;
                  final entry = TimetableEntry(
                    id: existing?.id ?? '',
                    subjectId: existing?.subjectId ?? '',
                    subjectName: subjectCtrl.text.trim(),
                    facultyId: facultyId,
                    dayOfWeek: selectedDay,
                    startTime: _formatTime(startTime),
                    endTime: _formatTime(endTime),
                    room: roomCtrl.text.trim(),
                  );
                  if (isEdit) {
                    ref.read(timetableNotifierProvider.notifier).updateEntry(entry);
                  } else {
                    ref.read(timetableNotifierProvider.notifier).addEntry(entry);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isEdit ? 'Lecture updated' : 'Lecture added'),
                    backgroundColor: AppColors.success,
                  ));
                },
                child: Text(isEdit ? 'Save Changes' : 'Add Lecture'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TimetableEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lecture'),
        content: Text('Remove "${entry.subjectName}" from your schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(timetableNotifierProvider.notifier).deleteEntry(entry.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Lecture removed'),
                backgroundColor: AppColors.error,
              ));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─── Editable Timetable Card ──────────────────────────────────────────────────

class _EditableTimetableCard extends StatelessWidget {
  final TimetableEntry entry;
  final bool isToday;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EditableTimetableCard({
    required this.entry,
    required this.isToday,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            // Color bar
            Container(
              width: 4, height: 44,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.subjectName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(entry.room, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
            ])),
            // Time
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(entry.timeRange,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              // Edit/delete actions
              Row(children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                  ),
                ),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Time Picker Tile ─────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onPick;
  const _TimePicker({required this.label, required this.time, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text(formatted, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ])),
        ]),
      ),
    );
  }
}
