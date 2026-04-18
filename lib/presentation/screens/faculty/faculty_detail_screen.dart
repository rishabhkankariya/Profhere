import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/faculty.dart';
import '../../../domain/entities/consultation.dart';
import '../../../domain/entities/academic.dart';
import '../../providers/faculty_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/academic_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/faculty_avatar.dart';

class FacultyDetailScreen extends ConsumerWidget {
  final String facultyId;
  const FacultyDetailScreen({super.key, required this.facultyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(facultyByIdProvider(facultyId));
    return async.when(
      data: (f) => f == null
          ? Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => context.go(AppRoutes.faculties),
                ),
              ),
              body: const Center(child: Text('Faculty not found')),
            )
          : _DetailView(faculty: f),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
    );
  }
}

class _DetailView extends ConsumerWidget {
  final Faculty faculty;
  const _DetailView({required this.faculty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final queueAsync = ref.watch(consultationsByFacultyProvider(faculty.id));

    // Check if current student is already in queue
    final myRequest = queueAsync.whenData((list) => list.where((c) =>
        c.studentId == (user?.id ?? '') &&
        (c.status == ConsultationStatus.pending ||
            c.status == ConsultationStatus.inProgress)).firstOrNull);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(children: [
                _buildStatusCard(queueAsync),
                const SizedBox(height: 12),
                // My queue status banner
                myRequest.when(
                  data: (mine) => mine != null ? _MyQueueBanner(consultation: mine) : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                myRequest.when(
                  data: (mine) => mine != null ? const SizedBox(height: 12) : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                _buildInfoCard(),
                const SizedBox(height: 12),
                myRequest.when(
                  data: (mine) => _buildActionRow(context, ref, alreadyInQueue: mine != null),
                  loading: () => _buildActionRow(context, ref, alreadyInQueue: false),
                  error: (_, __) => _buildActionRow(context, ref, alreadyInQueue: false),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      expandedHeight: 190,
      leading: IconButton(
        icon: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
        ),
        onPressed: () {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            context.go(AppRoutes.faculties);
          }
        },
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_rounded, size: 18, color: AppColors.primary),
          ),
          tooltip: 'Share QR Code',
          onPressed: () => _showQRCode(context),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.surface,
          child: SafeArea(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 32),
              FacultyAvatar(
                avatarBase64: faculty.avatarUrl,
                initials: faculty.initials,
                size: 72,
                borderRadius: 22,
              ),
              const SizedBox(height: 10),
              Text(faculty.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text(faculty.department,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    final qrData = 'https://profhere.web.app/#/faculty/${faculty.id}';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),

            // Title
            Text('${faculty.name}\'s QR Code',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Scan to open this faculty\'s profile',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),

            // QR Code
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF4F46E5),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Faculty info below QR
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FacultyAvatar(
                avatarBase64: faculty.avatarUrl,
                initials: faculty.initials,
                size: 32,
                borderRadius: 10,
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(faculty.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(faculty.department,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ]),
            const SizedBox(height: 20),

            // Copy link button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrData));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Profile link copied to clipboard'),
                    backgroundColor: AppColors.success,
                  ));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Profile Link'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatusCard(AsyncValue<List<Consultation>> queueAsync) {
    // Show 0 while loading — never show grey block
    final waitingCount = queueAsync.maybeWhen(
      data: (list) => list.where((c) => c.status == ConsultationStatus.pending).length,
      orElse: () => 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: faculty.status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(faculty.status.icon, color: faculty.status.color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Current Status', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(faculty.status.label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: faculty.status.color)),
          if (faculty.activeContext != null)
            Text(faculty.activeContext!,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis),
        ])),
        if (waitingCount > 0)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$waitingCount',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.warning)),
            const Text('in queue', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ])
        else if (faculty.expectedReturnAt != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Returns', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text(
              '${faculty.expectedReturnAt!.hour.toString().padLeft(2, '0')}:${faculty.expectedReturnAt!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ]),
      ]),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Information',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          // QR share button — always visible, works on web & mobile
          Builder(builder: (ctx) => GestureDetector(
            onTap: () => _showQRCode(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.qr_code_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 5),
                Text('Share QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: faculty.email),
        _InfoRow(icon: Icons.location_on_outlined, label: 'Office',
            value: '${faculty.building}, ${faculty.cabinId}'),
        if (faculty.specialization != null)
          _InfoRow(icon: Icons.science_outlined, label: 'Specialization', value: faculty.specialization!),
        if (faculty.zone != null)
          _InfoRow(icon: Icons.layers_outlined, label: 'Zone', value: faculty.zone!),
      ]),
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref, {required bool alreadyInQueue}) {
    return Row(children: [
      // Schedule button
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showScheduleSheet(context, ref),
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: const Text('Schedule'),
        ),
      ),
      const SizedBox(width: 12),
      // Queue button
      Expanded(
        child: alreadyInQueue
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Already in Queue', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            : ElevatedButton.icon(
                onPressed: () => _showQueueSheet(context, ref),
                icon: const Icon(Icons.queue_rounded, size: 16),
                label: const Text('Join Queue'),
              ),
      ),
    ]);
  }

  void _showScheduleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => _ScheduleView(
          facultyId: faculty.id,
          facultyName: faculty.name,
          scrollController: ctrl,
        ),
      ),
    );
  }

  void _showQueueSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) => Padding(
        // Pushes sheet above keyboard — no scrolling needed
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(faculty.initials,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(faculty.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                Text(faculty.department, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: faculty.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(faculty.status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: faculty.status.color)),
              ),
            ]),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Purpose of consultation',
                hintText: 'e.g. Project discussion, grade query…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                Navigator.pop(sheetCtx);
                final user = ref.read(authNotifierProvider).user;
                if (user == null) return;
                final result = await ref.read(consultationNotifierProvider.notifier).joinQueue(
                  facultyId: faculty.id,
                  studentId: user.id,
                  studentName: user.name,
                  purpose: ctrl.text.trim(),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result != null
                      ? 'Joined queue — position #${result.position}, ~${result.waitTimeMinutes} min wait'
                      : ref.read(consultationNotifierProvider).error?.toString() ?? 'Could not join queue'),
                  backgroundColor: result != null ? AppColors.success : AppColors.error,
              ));
            },
            child: const Text('Confirm & Join Queue'),
          ),
        ]),
        ),
      ),
    );
  }
}

// ─── My Queue Banner ──────────────────────────────────────────────────────────

class _MyQueueBanner extends StatelessWidget {
  final Consultation consultation;
  const _MyQueueBanner({required this.consultation});

  @override
  Widget build(BuildContext context) {
    final isActive = consultation.status == ConsultationStatus.inProgress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successBg : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.success.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        Icon(
          isActive ? Icons.play_circle_outline_rounded : Icons.queue_rounded,
          color: isActive ? AppColors.success : AppColors.primary,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isActive ? 'Your consultation is in progress!' : 'You are in the queue',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isActive
                ? 'Please proceed to the faculty cabin'
                : 'Position #${consultation.position} · ~${consultation.waitTimeMinutes} min wait',
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.success : AppColors.primaryDark,
            ),
          ),
        ])),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppColors.textMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Schedule View ────────────────────────────────────────────────────────────

class _ScheduleView extends ConsumerWidget {
  final String facultyId;
  final String facultyName;
  final ScrollController scrollController;
  const _ScheduleView({required this.facultyId, required this.facultyName, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttAsync = ref.watch(facultyTimetableProvider(facultyId));
    final today = DateTime.now().weekday;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // Handle bar
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Lecture Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(facultyName, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        // Schedule list
        Expanded(
          child: ttAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text('No schedule available',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('This faculty has not added their lecture schedule yet',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                        Text(
                          dayNames[d - 1],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isToday ? AppColors.primary : AppColors.textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('TODAY',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                        ],
                      ]),
                    ),
                    ...byDay[d]!.map((e) => _ScheduleCard(entry: e, isToday: isToday)),
                  ]);
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ]),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final TimetableEntry entry;
  final bool isToday;
  const _ScheduleCard({required this.entry, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Time column
        Column(children: [
          Text(entry.startTime,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Container(
            width: 1,
            height: 20,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          Text(entry.endTime, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
        const SizedBox(width: 14),
        // Color bar
        Container(
          width: 4,
          height: 44,
          decoration: BoxDecoration(
            color: isToday ? AppColors.primary : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.subjectName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(entry.room, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
