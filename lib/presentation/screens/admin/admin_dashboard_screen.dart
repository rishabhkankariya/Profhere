// Admin Dashboard Screen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/consultation.dart';
import '../../../domain/entities/faculty.dart';
import '../../../domain/entities/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/faculty_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/faculty_avatar.dart';
import '../community/faculty_community_screen.dart';

// ─── Main Screen ──────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboardScreen> {
  int _tab = 0;
  static const _tabs = ['Overview', 'Faculty', 'Students', 'Queue', 'Community'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Data',
            onPressed: () {
              // Invalidate all data providers to refresh
              ref.invalidate(facultyListProvider);
              ref.invalidate(allStudentsProvider);
              ref.invalidate(allConsultationsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing data...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset_rounded, size: 20),
            tooltip: 'Change Password',
            onPressed: () => _showChangePasswordSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              final router = GoRouter.of(context);
              await ref.read(authNotifierProvider.notifier).logout();
              router.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Column(children: [
        _buildTabBar(),
        Expanded(child: IndexedStack(index: _tab, children: [
          _OverviewTab(),
          _FacultyTab(),
          _StudentsTab(),
          _QueueTab(),
          const FacultyCommunityScreen(isEmbedded: true),
        ])),
      ]),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_tab == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'bulk',
            mini: true,
            backgroundColor: AppColors.surface,
            onPressed: () => _showBulkUploadSheet(context),
            child: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _showAddFacultySheet(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Add Faculty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }
    return null;
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: List.generate(_tabs.length, (i) {
          final active = _tab == i;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: active ? AppColors.primary : Colors.transparent,
                  width: 2,
                )),
              ),
              child: Text(_tabs[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textMuted,
                  )),
            ),
          );
        })),
      ),
    );
  }

  // ── Change Password ──────────────────────────────────────────────────────────
  void _showChangePasswordSheet(BuildContext context) {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final c3 = TextEditingController();
    bool o1 = true, o2 = true, o3 = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Change My Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _PwField(ctrl: c1, label: 'Current password', obscure: o1, onToggle: () => ss(() => o1 = !o1)),
          const SizedBox(height: 12),
          _PwField(ctrl: c2, label: 'New password', obscure: o2, onToggle: () => ss(() => o2 = !o2)),
          const SizedBox(height: 12),
          _PwField(ctrl: c3, label: 'Confirm new password', obscure: o3, onToggle: () => ss(() => o3 = !o3)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (c1.text.isEmpty || c2.text.isEmpty) return;
              if (c2.text != c3.text) { _snack(context, 'Passwords do not match', error: true); return; }
              if (c2.text.length < 6) { _snack(context, 'Min 6 characters', error: true); return; }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).changeOwnPassword(currentPassword: c1.text, newPassword: c2.text);
              final err = ref.read(authNotifierProvider).error;
              messenger.showSnackBar(SnackBar(
                content: Text(err ?? 'Password changed'),
                backgroundColor: err != null ? AppColors.error : AppColors.success,
              ));
              if (err != null) ref.read(authNotifierProvider.notifier).clearError();
            },
            child: const Text('Change Password'),
          ),
        ]),
      )),
    );
  }

  // ── Add Faculty ──────────────────────────────────────────────────────────────
  void _showAddFacultySheet(BuildContext context) {
    final name  = TextEditingController();
    final email = TextEditingController();
    final dept  = TextEditingController();
    final bldg  = TextEditingController();
    final cabin = TextEditingController();
    final spec  = TextEditingController();
    final phone = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add New Faculty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _Field(ctrl: name,  label: 'Full Name *'),
            const SizedBox(height: 12),
            _Field(ctrl: email, label: 'Email *', type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _Field(ctrl: dept,  label: 'Department *'),
            const SizedBox(height: 12),
            _Field(ctrl: bldg,  label: 'Building'),
            const SizedBox(height: 12),
            _Field(ctrl: cabin, label: 'Cabin / Room ID'),
            const SizedBox(height: 12),
            _Field(ctrl: spec,  label: 'Specialization'),
            const SizedBox(height: 12),
            _Field(ctrl: phone, label: 'Phone (optional)', type: TextInputType.phone),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (name.text.isEmpty || email.text.isEmpty || dept.text.isEmpty) {
                  _snack(context, 'Name, email and department are required', error: true);
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                final facultyName = name.text.trim();
                Navigator.pop(context);
                await ref.read(facultyNotifierProvider.notifier).addFaculty(Faculty(
                  id: '', name: facultyName, email: email.text.trim(),
                  department: dept.text.trim(), building: bldg.text.trim(),
                  cabinId: cabin.text.trim(),
                  specialization: spec.text.trim().isEmpty ? null : spec.text.trim(),
                  phoneNumber: phone.text.trim().isEmpty ? null : phone.text.trim(),
                  status: FacultyStatus.available, lastUpdated: DateTime.now(),
                ));
                messenger.showSnackBar(SnackBar(
                  content: Text('$facultyName added'),
                  backgroundColor: AppColors.success,
                ));
              },
              child: const Text('Add Faculty'),
            ),
          ],
        )),
      ),
    );
  }

  // ── Bulk Excel Upload ────────────────────────────────────────────────────────
  void _showBulkUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BulkUploadSheet(
        onImported: (facultyCount) => _snack(context, '$facultyCount faculty imported successfully'),
        onError: (msg) => _snack(context, msg, error: true),
      ),
    );
  }

  void _snack(BuildContext ctx, String msg, {bool error = false}) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyAsync  = ref.watch(facultyListProvider);
    final studentsAsync = ref.watch(allStudentsProvider);
    final queueAsync    = ref.watch(allConsultationsProvider);

    final faculties = facultyAsync.value ?? [];
    final students  = studentsAsync.value ?? [];
    final queues    = queueAsync.value ?? [];

    final available = faculties.where((f) => f.status == FacultyStatus.available).length;
    final pending   = queues.where((q) => (q['statusIndex'] as int? ?? 0) == ConsultationStatus.pending.index).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Admin credentials info ─────────────────────────────────────
        _AdminCredentialsCard(),
        const SizedBox(height: 16),
        // Top stats
        Row(children: [
          Expanded(child: _StatCard(label: 'Faculty', value: '${faculties.length}', color: AppColors.primary, icon: Icons.people_alt_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Students', value: '${students.length}', color: AppColors.info, icon: Icons.school_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Available', value: '$available', color: AppColors.success, icon: Icons.check_circle_outline_rounded)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatCard(label: 'In Queue', value: '$pending', color: AppColors.warning, icon: Icons.queue_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Total Consults', value: '${queues.length}', color: AppColors.meeting, icon: Icons.handshake_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Completed', value: '${queues.where((q) => (q['statusIndex'] as int? ?? 0) == ConsultationStatus.completed.index).length}', color: AppColors.success, icon: Icons.done_all_rounded)),
        ]),
        const SizedBox(height: 20),
        const Text('Faculty Status Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...FacultyStatus.values.map((s) {
          final count = faculties.where((f) => f.status == s).length;
          final pct = faculties.isEmpty ? 0.0 : count / faculties.length;
          return _StatusBar(status: s, count: count, pct: pct);
        }),
        const SizedBox(height: 20),
        const Text('Recent Queue Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...queues.take(5).map((q) => _QueueRow(data: q)),
      ]),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _QueueRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final statusIdx = data['statusIndex'] as int? ?? 0;
    final status = ConsultationStatus.values[statusIdx.clamp(0, ConsultationStatus.values.length - 1)];
    final ts = (data['requestedAt'] as Timestamp?)?.toDate();
    final timeStr = ts != null
        ? '${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}'
        : '--';
    final colors = [AppColors.warning, AppColors.info, AppColors.success, AppColors.error, AppColors.textMuted];
    final color = colors[statusIdx.clamp(0, colors.length - 1)];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['studentName'] as String? ?? 'Unknown',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(data['purpose'] as String? ?? '',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
            child: Text(status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(height: 2),
          Text(timeStr, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

// ─── Faculty Tab ──────────────────────────────────────────────────────────────

class _FacultyTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FacultyTab> createState() => _FacultyTabState();
}

class _FacultyTabState extends ConsumerState<_FacultyTab> {
  String _search = '';
  String? _deptFilter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(facultyListProvider);
    final depts = ref.watch(departmentsProvider);

    return async.when(
      data: (all) {
        var list = all.where((f) {
          final q = _search.toLowerCase();
          final matchSearch = q.isEmpty ||
              f.name.toLowerCase().contains(q) ||
              f.email.toLowerCase().contains(q) ||
              f.department.toLowerCase().contains(q);
          final matchDept = _deptFilter == null || f.department == _deptFilter;
          return matchSearch && matchDept;
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Column(children: [
          // Search + filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Search faculty…',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String?>(
                value: _deptFilter,
                hint: const Text('Dept', style: TextStyle(fontSize: 13)),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...depts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (v) => setState(() => _deptFilter = v),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Text('${list.length} faculty', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No faculty found', style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _FacultyAdminCard(
                      faculty: list[i],
                      onEdit:     () => _showEditSheet(context, list[i]),
                      onDelete:   () => _confirmDelete(context, list[i]),
                      onQr:       () => _showQr(context, list[i]),
                      onStatus:   () => _showStatusSheet(context, list[i]),
                      onPassword: () => _showPasswordSheet(context, list[i]),
                    ),
                  ),
          ),
        ]);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  void _showPasswordSheet(BuildContext context, Faculty f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FacultyPasswordSheet(faculty: f),
    );
  }

  void _showEditSheet(BuildContext context, Faculty f) {
    final name  = TextEditingController(text: f.name);
    final email = TextEditingController(text: f.email);
    final dept  = TextEditingController(text: f.department);
    final bldg  = TextEditingController(text: f.building);
    final cabin = TextEditingController(text: f.cabinId);
    final spec  = TextEditingController(text: f.specialization ?? '');
    final phone = TextEditingController(text: f.phoneNumber ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit Faculty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _Field(ctrl: name,  label: 'Full Name'),
            const SizedBox(height: 12),
            _Field(ctrl: email, label: 'Email', type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _Field(ctrl: dept,  label: 'Department'),
            const SizedBox(height: 12),
            _Field(ctrl: bldg,  label: 'Building'),
            const SizedBox(height: 12),
            _Field(ctrl: cabin, label: 'Cabin / Room ID'),
            const SizedBox(height: 12),
            _Field(ctrl: spec,  label: 'Specialization'),
            const SizedBox(height: 12),
            _Field(ctrl: phone, label: 'Phone Number', type: TextInputType.phone),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (name.text.isEmpty || email.text.isEmpty) return;
                ref.read(facultyNotifierProvider.notifier).updateFaculty(f.copyWith(
                  name: name.text.trim(), email: email.text.trim(),
                  department: dept.text.trim(), building: bldg.text.trim(),
                  cabinId: cabin.text.trim(),
                  specialization: spec.text.trim().isEmpty ? null : spec.text.trim(),
                  phoneNumber: phone.text.trim().isEmpty ? null : phone.text.trim(),
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Faculty updated'), backgroundColor: AppColors.success));
              },
              child: const Text('Save Changes'),
            ),
          ],
        )),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Faculty f) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text('Remove ${f.name} from the system? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(facultyNotifierProvider.notifier).deleteFaculty(f.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showQr(BuildContext context, Faculty f) {
    final qrData = 'profhere://faculty/${f.id}';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(f.initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(f.department, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: SizedBox(width: 200, height: 200,
                child: QrImageView(data: qrData, version: QrVersions.auto, size: 200, backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)))),
            ),
            const SizedBox(height: 12),
            Text(f.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))),
          ]),
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, Faculty f) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _StatusSheet(facultyId: f.id, parentContext: context),
    );
  }
}

// ─── Students Tab ─────────────────────────────────────────────────────────────

class _StudentsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends ConsumerState<_StudentsTab> {
  String _search = '';
  bool _showBlockedOnly = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(allStudentsProvider);
    final blockedAsync  = ref.watch(blockedStudentsProvider);
    final blocked = blockedAsync.value ?? {};

    return studentsAsync.when(
      data: (all) {
        var list = all.where((s) {
          final q = _search.toLowerCase();
          final matchSearch = q.isEmpty ||
              s.name.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q) ||
              (s.studentCode?.toLowerCase().contains(q) ?? false) ||
              (s.department?.toLowerCase().contains(q) ?? false);
          final matchBlocked = !_showBlockedOnly || blocked.contains(s.id);
          return matchSearch && matchBlocked;
        }).toList();

        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Search students…',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Blocked', style: TextStyle(fontSize: 12)),
                selected: _showBlockedOnly,
                onSelected: (v) => setState(() => _showBlockedOnly = v),
                selectedColor: AppColors.error.withValues(alpha: 0.15),
                checkmarkColor: AppColors.error,
                labelStyle: TextStyle(color: _showBlockedOnly ? AppColors.error : AppColors.textMuted),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Text('${list.length} students · ${blocked.length} blocked',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No students found', style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _StudentCard(
                      student: list[i],
                      isBlocked: blocked.contains(list[i].id),
                      onBlock: () => ref.read(adminUserNotifierProvider.notifier).blockStudent(list[i].id),
                      onUnblock: () => ref.read(adminUserNotifierProvider.notifier).unblockStudent(list[i].id),
                      onDelete: () => _confirmDeleteStudent(context, list[i]),
                      onView: () => _showStudentDetail(context, list[i]),
                    ),
                  ),
          ),
        ]);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  void _confirmDeleteStudent(BuildContext context, User s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Remove ${s.name} from the system? Their account data will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(adminUserNotifierProvider.notifier).deleteStudent(s.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetail(BuildContext context, User s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StudentDetailSheet(student: s),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final User student;
  final bool isBlocked;
  final VoidCallback onBlock, onUnblock, onDelete, onView;
  const _StudentCard({required this.student, required this.isBlocked,
      required this.onBlock, required this.onUnblock, required this.onDelete, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBlocked ? AppColors.error.withValues(alpha: 0.4) : AppColors.border,
          width: isBlocked ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: isBlocked
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.primaryLight,
          child: Text(student.initials,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: isBlocked ? AppColors.error : AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(student.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis)),
            if (isBlocked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(4)),
                child: const Text('BLOCKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.error)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(student.email, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
          if (student.department != null)
            Text(student.department!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
          onSelected: (v) {
            switch (v) {
              case 'view':    onView();
              case 'block':   onBlock();
              case 'unblock': onUnblock();
              case 'delete':  onDelete();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.info_outline_rounded, size: 16), SizedBox(width: 8), Text('View Details')])),
            if (!isBlocked)
              const PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block_rounded, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Block', style: TextStyle(color: AppColors.error))])),
            if (isBlocked)
              const PopupMenuItem(value: 'unblock', child: Row(children: [Icon(Icons.lock_open_rounded, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Unblock', style: TextStyle(color: AppColors.success))])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
          ],
        ),
      ]),
    );
  }
}

class _StudentDetailSheet extends StatelessWidget {
  final User student;
  const _StudentDetailSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            CircleAvatar(radius: 28, backgroundColor: AppColors.primaryLight,
                child: Text(student.initials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(student.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(student.email, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ])),
          ]),
          const SizedBox(height: 24),
          const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _DetailRow(icon: Icons.badge_outlined, label: 'Roll No', value: student.studentCode ?? '—'),
          _DetailRow(icon: Icons.business_outlined, label: 'Department', value: student.department ?? '—'),
          _DetailRow(icon: Icons.school_outlined, label: 'Year', value: student.yearOfStudy != null ? 'Year ${student.yearOfStudy}' : '—'),
          _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: student.phoneNumber ?? '—'),
          _DetailRow(icon: Icons.calendar_today_outlined, label: 'Joined', value: _fmt(student.createdAt)),
          _DetailRow(icon: Icons.login_rounded, label: 'Last Login', value: _fmt(student.lastLoginAt)),
        ]),
      ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month-1]} ${dt.day}, ${dt.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ]),
    );
  }
}

// ─── Queue Tab ────────────────────────────────────────────────────────────────

class _QueueTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends ConsumerState<_QueueTab> {
  String _search = '';
  int _statusFilter = -1; // -1 = all

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(allConsultationsProvider);
    final facultyAsync = ref.watch(facultyListProvider);
    final facultyMap = <String, String>{for (final f in (facultyAsync.value ?? [])) f.id: f.name};

    return queueAsync.when(
      data: (all) {
        var list = all.where((q) {
          final s = _search.toLowerCase();
          final matchSearch = s.isEmpty ||
              (q['studentName'] as String? ?? '').toLowerCase().contains(s) ||
              (q['purpose'] as String? ?? '').toLowerCase().contains(s);
          final matchStatus = _statusFilter == -1 ||
              (q['statusIndex'] as int? ?? 0) == _statusFilter;
          return matchSearch && matchStatus;
        }).toList();

        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search by student or purpose…',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: 'All', active: _statusFilter == -1, onTap: () => setState(() => _statusFilter = -1)),
                ...ConsultationStatus.values.map((s) => _FilterChip(
                  label: s.label,
                  active: _statusFilter == s.index,
                  onTap: () => setState(() => _statusFilter = s.index),
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text('${list.length} records', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No queue records', style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _QueueAdminCard(data: list[i], facultyMap: facultyMap),
                  ),
          ),
        ]);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _QueueAdminCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, String> facultyMap;
  const _QueueAdminCard({required this.data, required this.facultyMap});

  @override
  Widget build(BuildContext context) {
    final statusIdx = (data['statusIndex'] as int? ?? 0).clamp(0, ConsultationStatus.values.length - 1);
    final status = ConsultationStatus.values[statusIdx];
    final colors = [AppColors.warning, AppColors.info, AppColors.success, AppColors.error, AppColors.textMuted];
    final color = colors[statusIdx.clamp(0, colors.length - 1)];
    final ts = (data['requestedAt'] as Timestamp?)?.toDate();
    final timeStr = ts != null ? '${ts.day}/${ts.month} ${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}' : '--';
    final facultyName = facultyMap[data['facultyId'] as String? ?? ''] ?? 'Unknown Faculty';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(data['studentName'] as String? ?? 'Unknown',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(data['purpose'] as String? ?? '',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.person_outlined, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(child: Text(facultyName, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
          const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

// ─── Faculty Admin Card ───────────────────────────────────────────────────────

class _FacultyAdminCard extends ConsumerWidget {
  final Faculty faculty;
  final VoidCallback onEdit, onDelete, onQr, onStatus, onPassword;
  const _FacultyAdminCard({required this.faculty, required this.onEdit,
      required this.onDelete, required this.onQr, required this.onStatus, required this.onPassword});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(facultyByIdStreamProvider(faculty.id));
    final live = liveAsync.value ?? faculty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: live.status == FacultyStatus.available
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(children: [
        Row(children: [
          FacultyAvatar(avatarBase64: live.avatarUrl, initials: live.initials, size: 48, borderRadius: 13),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(live.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('${live.department} · ${live.building}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (live.phoneNumber != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.phone_outlined, size: 11, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(live.phoneNumber!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ],
            const SizedBox(height: 4),
            _StatusBadge(live.status, live.customStatusText),
          ])),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ActionBtn(icon: Icons.swap_horiz_rounded, label: 'Status',   onTap: onStatus),
          _ActionBtn(icon: Icons.qr_code_2_rounded,  label: 'QR',       onTap: onQr),
          _ActionBtn(icon: Icons.edit_outlined,       label: 'Edit',     onTap: onEdit),
          _ActionBtn(icon: Icons.key_rounded,         label: 'Password', onTap: onPassword),
          _ActionBtn(icon: Icons.delete_outline_rounded, label: 'Delete', onTap: onDelete, color: AppColors.error),
        ]),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FacultyStatus status;
  final String? customText;
  const _StatusBadge(this.status, this.customText);

  @override
  Widget build(BuildContext context) {
    final label = (status == FacultyStatus.custom && customText != null && customText!.isNotEmpty)
        ? customText!
        : status.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status.color),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── Faculty Password Sheet ───────────────────────────────────────────────────

class _FacultyPasswordSheet extends ConsumerStatefulWidget {
  final Faculty faculty;
  const _FacultyPasswordSheet({required this.faculty});
  @override
  ConsumerState<_FacultyPasswordSheet> createState() => _FacultyPasswordSheetState();
}

class _FacultyPasswordSheetState extends ConsumerState<_FacultyPasswordSheet> {
  bool _loading = false;
  String? _generatedDemo;

  Future<void> _generateDemo() async {
    setState(() => _loading = true);
    final demo = await ref.read(authNotifierProvider.notifier).createFacultyWithDemoPassword(
      email: widget.faculty.email,
      name: widget.faculty.name,
      facultyFirestoreId: widget.faculty.id,
    );
    if (!mounted) return;
    setState(() { _loading = false; _generatedDemo = demo; });
    if (demo == null) {
      final err = ref.read(authNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Failed to create account'),
        backgroundColor: AppColors.error,
      ));
      ref.read(authNotifierProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.faculty.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(widget.faculty.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
        ]),
        const SizedBox(height: 16),

        if (_generatedDemo != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text('Account created!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
              ]),
              const SizedBox(height: 10),
              const Text('Demo password (share with faculty):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: Text(_generatedDemo!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: AppColors.textPrimary)),
                )),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedDemo!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                  },
                ),
              ]),
              const SizedBox(height: 8),
              const Text('A password reset email has also been sent to the faculty. They must change their password on first login.', style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Text(
              'This will create a Firebase Auth account with an auto-generated demo password. A password reset email is sent automatically. The faculty must change their password on first login.',
              style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _generateDemo,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Generate Demo Password & Create Account'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final email = widget.faculty.email;
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).sendFacultyPasswordReset(email);
              messenger.showSnackBar(SnackBar(
                content: Text('Reset email sent to $email'),
                backgroundColor: AppColors.success,
              ));
            },
            icon: const Icon(Icons.email_outlined, size: 16),
            label: const Text('Send reset email only'),
          ),
        ],
      ]),
    );
  }
}

// ─── Status Sheet ─────────────────────────────────────────────────────────────

class _StatusSheet extends ConsumerWidget {
  final String facultyId;
  final BuildContext parentContext;
  const _StatusSheet({required this.facultyId, required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(facultyByIdStreamProvider(facultyId));
    final faculty = liveAsync.value;
    if (faculty == null) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(faculty.initials, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(faculty.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            _StatusBadge(faculty.status, faculty.customStatusText),
          ])),
        ]),
        const SizedBox(height: 20),
        const Text('Set Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: FacultyStatus.values.map((s) {
          final isActive = faculty.status == s;
          return GestureDetector(
            onTap: () {
              ref.read(facultyNotifierProvider.notifier).updateStatus(facultyId, s);
              Navigator.pop(context);
              ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
                content: Text('${faculty.name} → ${s.label}'),
                backgroundColor: s.color,
              ));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? s.color : s.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: s.color.withValues(alpha: isActive ? 1.0 : 0.3), width: isActive ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(s.icon, size: 14, color: isActive ? Colors.white : s.color),
                const SizedBox(width: 6),
                Text(s.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : s.color)),
              ]),
            ),
          );
        }).toList()),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ─── Bulk Upload Sheet ────────────────────────────────────────────────────────

class _BulkUploadSheet extends ConsumerStatefulWidget {
  final void Function(int) onImported;
  final void Function(String) onError;
  const _BulkUploadSheet({required this.onImported, required this.onError});
  @override
  ConsumerState<_BulkUploadSheet> createState() => _BulkUploadSheetState();
}

class _BulkUploadSheetState extends ConsumerState<_BulkUploadSheet> {
  List<Map<String, String>> _preview = [];
  bool _loading = false;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final bytes = result.files.single.bytes!;
    _fileName = result.files.single.name;
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.isEmpty) { widget.onError('Empty spreadsheet'); return; }

      // Skip header row, parse data
      final parsed = <Map<String, String>>[];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        String cell(int idx) => row.length > idx ? (row[idx]?.value?.toString() ?? '').trim() : '';
        final name  = cell(0);
        final email = cell(1);
        final dept  = cell(2);
        final bldg  = cell(3);
        final cabin = cell(4);
        final spec  = cell(5);
        final phone = cell(6);
        if (name.isEmpty || email.isEmpty) continue;
        parsed.add({'name': name, 'email': email, 'dept': dept, 'bldg': bldg, 'cabin': cabin, 'spec': spec, 'phone': phone});
      }
      setState(() { _preview = parsed; });
    } catch (e) {
      widget.onError('Failed to parse file: $e');
    }
  }

  Future<void> _import() async {
    if (_preview.isEmpty) return;
    setState(() => _loading = true);
    int count = 0;
    for (final row in _preview) {
      try {
        await ref.read(facultyNotifierProvider.notifier).addFaculty(Faculty(
          id: '', name: row['name']!, email: row['email']!,
          department: row['dept'] ?? '', building: row['bldg'] ?? '',
          cabinId: row['cabin'] ?? '',
          specialization: (row['spec'] ?? '').isEmpty ? null : row['spec'],
          phoneNumber: (row['phone'] ?? '').isEmpty ? null : row['phone'],
          status: FacultyStatus.available, lastUpdated: DateTime.now(),
        ));
        count++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
    widget.onImported(count);
  }

  void _downloadSample() {
    // Show the expected format in a dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excel Format'),
        content: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('A\nName *', style: TextStyle(fontSize: 11))),
              DataColumn(label: Text('B\nEmail *', style: TextStyle(fontSize: 11))),
              DataColumn(label: Text('C\nDept', style: TextStyle(fontSize: 11))),
              DataColumn(label: Text('D\nBuilding', style: TextStyle(fontSize: 11))),
              DataColumn(label: Text('E\nCabin', style: TextStyle(fontSize: 11))),
              DataColumn(label: Text('F\nSpec', style: TextStyle(fontSize: 11))),
              DataColumn(label: Text('G\nPhone', style: TextStyle(fontSize: 11))),
            ],
            rows: const [
              DataRow(cells: [
                DataCell(Text('Dr. John Smith', style: TextStyle(fontSize: 11))),
                DataCell(Text('john@college.edu', style: TextStyle(fontSize: 11))),
                DataCell(Text('CS', style: TextStyle(fontSize: 11))),
                DataCell(Text('Block A', style: TextStyle(fontSize: 11))),
                DataCell(Text('A-101', style: TextStyle(fontSize: 11))),
                DataCell(Text('AI/ML', style: TextStyle(fontSize: 11))),
                DataCell(Text('9876543210', style: TextStyle(fontSize: 11))),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('Bulk Import Faculty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            TextButton.icon(
              onPressed: _downloadSample,
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              label: const Text('Format', style: TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Upload an Excel (.xlsx) file with faculty data. Row 1 is the header.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_fileName ?? 'Choose Excel File'),
          ),
          if (_preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
              child: Text('${_preview.length} faculty rows found and ready to import', style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                itemCount: _preview.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight,
                      child: Text(_preview[i]['name']![0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  title: Text(_preview[i]['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(_preview[i]['email']!, style: const TextStyle(fontSize: 11)),
                  trailing: Text(_preview[i]['dept'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _import,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Import ${_preview.length} Faculty'),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── Admin Credentials Card ───────────────────────────────────────────────────

class _AdminCredentialsCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AdminCredentialsCard> createState() => _AdminCredentialsCardState();
}

class _AdminCredentialsCardState extends ConsumerState<_AdminCredentialsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(facultyListProvider);
    final faculties = facultyAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Account Credentials',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Demo accounts & faculty passwords',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ]),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 20, color: AppColors.textMuted,
              ),
            ]),
          ),
        ),
        // Expandable credentials
        if (_expanded) ...[
          const Divider(height: 1, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(children: [
              // Demo accounts section
              const Row(children: [
                Text('Demo Accounts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(width: 8),
                Expanded(child: Divider(height: 1)),
              ]),
              const SizedBox(height: 8),
              _CredRow(role: 'Admin', email: 'admin@profhere.com', password: 'admin123', color: AppColors.error),
              const SizedBox(height: 8),
              _CredRow(role: 'Faculty', email: 'sarah.mitchell@profhere.com', password: 'faculty123', color: AppColors.primary),
              const SizedBox(height: 8),
              _CredRow(role: 'Student', email: 'alex.thompson@student.profhere.com', password: 'student123', color: AppColors.info),
              
              // Faculty accounts section
              if (faculties.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Row(children: [
                  Text('Faculty Accounts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  SizedBox(width: 8),
                  Expanded(child: Divider(height: 1)),
                ]),
                const SizedBox(height: 8),
                ...faculties.take(5).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FacultyCredRow(faculty: f),
                )),
                if (faculties.length > 5)
                  Text('... and ${faculties.length - 5} more faculty accounts',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}

class _FacultyCredRow extends StatelessWidget {
  final Faculty faculty;
  const _FacultyCredRow({required this.faculty});

  @override
  Widget build(BuildContext context) {
    // Generate the same demo password format as used in auth repository
    final firstName = faculty.name.split(' ').first;
    final demoPassword = '${firstName.toLowerCase()}123'; // Simplified demo password for display
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text('Faculty',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(faculty.email,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(demoPassword,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, fontFamily: 'monospace',
              )),
        ])),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.textMuted),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '${faculty.email}  /  $demoPassword'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Faculty credentials copied'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        ),
      ]),
    );
  }
}

class _CredRow extends StatelessWidget {
  final String role, email, password;
  final Color color;
  const _CredRow({required this.role, required this.email, required this.password, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(role,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(email,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(password,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, fontFamily: 'monospace',
              )),
        ])),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.textMuted),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '$email  /  $password'));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$role credentials copied'),
                duration: const Duration(seconds: 2),
                backgroundColor: color,
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final FacultyStatus status;
  final int count;
  final double pct;
  const _StatusBar({required this.status, required this.count, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: Text(status.label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation(status.color)))),
        const SizedBox(width: 10),
        SizedBox(width: 24, child: Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.right)),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;
  const _Field({required this.ctrl, required this.label, this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(controller: ctrl, keyboardType: type, decoration: InputDecoration(labelText: label));
  }
}

class _PwField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PwField({required this.ctrl, required this.label, required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
