import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/faculty.dart';
import '../../providers/faculty_provider.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/faculty_avatar.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset_rounded, size: 20),
            tooltip: 'Change My Password',
            onPressed: () => _showChangePasswordSheet(context, ref),
          ),
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
          _OverviewTab(),
          _FacultyManagementTab(),
        ])),
      ]),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddFacultySheet(context, ref),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Faculty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Overview', 'Faculty'];
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

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure1 = true, obscure2 = true, obscure3 = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Change My Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: currentCtrl,
              obscureText: obscure1,
              decoration: InputDecoration(
                labelText: 'Current password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setS(() => obscure1 = !obscure1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: obscure2,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setS(() => obscure2 = !obscure2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: obscure3,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(obscure3 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setS(() => obscure3 = !obscure3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty) return;
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('New passwords do not match'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).changeOwnPassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (context.mounted) {
                  final err = ref.read(authNotifierProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err ?? 'Password changed successfully'),
                    backgroundColor: err != null ? Colors.red : AppColors.success,
                  ));
                  if (err != null) ref.read(authNotifierProvider.notifier).clearError();
                }
              },
              child: const Text('Change Password'),
            ),
          ]),
        ),
      ),
    );
  }

  void _showAddFacultySheet(BuildContext context, WidgetRef ref) {    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl  = TextEditingController();
    final bldgCtrl  = TextEditingController();
    final cabinCtrl = TextEditingController();
    final specCtrl  = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Add New Faculty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _SheetField(ctrl: nameCtrl,  label: 'Full Name'),
            const SizedBox(height: 12),
            _SheetField(ctrl: emailCtrl, label: 'Email', type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _SheetField(ctrl: deptCtrl,  label: 'Department'),
            const SizedBox(height: 12),
            _SheetField(ctrl: bldgCtrl,  label: 'Building'),
            const SizedBox(height: 12),
            _SheetField(ctrl: cabinCtrl, label: 'Cabin / Room ID'),
            const SizedBox(height: 12),
            _SheetField(ctrl: specCtrl,  label: 'Specialization (optional)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                ref.read(facultyNotifierProvider.notifier).addFaculty(Faculty(
                  id: '',
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  building: bldgCtrl.text.trim(),
                  cabinId: cabinCtrl.text.trim(),
                  specialization: specCtrl.text.trim().isEmpty ? null : specCtrl.text.trim(),
                  status: FacultyStatus.available,
                  lastUpdated: DateTime.now(),
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Faculty added successfully'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Add Faculty'),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(facultyListProvider);
    return async.when(
      data: (faculties) {
        final available = faculties.where((f) => f.status == FacultyStatus.available).length;
        final inLecture = faculties.where((f) => f.status == FacultyStatus.inLecture).length;
        final away      = faculties.where((f) => f.status == FacultyStatus.away || f.status == FacultyStatus.notAvailable).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Stats row
            Row(children: [
              Expanded(child: _StatCard(label: 'Total', value: '${faculties.length}', color: AppColors.primary, icon: Icons.people_alt_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Available', value: '$available', color: AppColors.success, icon: Icons.check_circle_outline_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'In Lecture', value: '$inLecture', color: AppColors.error, icon: Icons.mic_outlined)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _StatCard(label: 'Away', value: '$away', color: AppColors.textMuted, icon: Icons.directions_walk_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Busy', value: '${faculties.where((f) => f.status == FacultyStatus.busy).length}', color: AppColors.warning, icon: Icons.schedule_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Meeting', value: '${faculties.where((f) => f.status == FacultyStatus.meeting).length}', color: AppColors.meeting, icon: Icons.groups_outlined)),
            ]),
            const SizedBox(height: 20),
            const Text('Status Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ...FacultyStatus.values.map((s) {
              final count = faculties.where((f) => f.status == s).length;
              final pct = faculties.isEmpty ? 0.0 : count / faculties.length;
              return _StatusBar(status: s, count: count, pct: pct);
            }),
          ]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
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
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: Text(status.label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(status.color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 24, child: Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.right)),
      ]),
    );
  }
}

// ─── Faculty Management Tab ───────────────────────────────────────────────────

class _FacultyManagementTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(facultyListProvider);
    return async.when(
      data: (faculties) => faculties.isEmpty
          ? const Center(child: Text('No faculty added yet', style: TextStyle(color: AppColors.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: faculties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _FacultyAdminCard(
                faculty: faculties[i],
                onEdit: () => _showEditSheet(context, ref, faculties[i]),
                onDelete: () => _confirmDelete(context, ref, faculties[i]),
                onQr: () => _showQr(context, faculties[i]),
                onStatus: () => _showStatusSheet(context, ref, faculties[i]),
                onPassword: () => _showPasswordSheet(context, ref, faculties[i]),
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  void _showPasswordSheet(BuildContext context, WidgetRef ref, Faculty f) {
    final passCtrl    = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure1 = true, obscure2 = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Text('Set login password', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
            ]),
            const SizedBox(height: 6),
            // Info about what this does
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'This creates a Firebase Auth account for ${f.name} using their email (${f.email}) and the password you set. They can then log in with these credentials.',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: obscure1,
              decoration: InputDecoration(
                labelText: 'Set password',
                prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setS(() => obscure1 = !obscure1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: obscure2,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setS(() => obscure2 = !obscure2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Alternative: send reset email
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).sendFacultyPasswordReset(f.email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Password reset email sent to ${f.email}'),
                    backgroundColor: AppColors.success,
                  ));
                }
              },
              icon: const Icon(Icons.email_outlined, size: 16),
              label: const Text('Send reset email instead'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                if (passCtrl.text.isEmpty) return;
                if (passCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                if (passCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Minimum 6 characters'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).createFacultyAccount(
                  email: f.email,
                  password: passCtrl.text,
                  facultyFirestoreId: f.id,
                );
                if (context.mounted) {
                  final err = ref.read(authNotifierProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err != null
                        ? 'Error: $err'
                        : '${f.name} account created. They can now log in.'),
                    backgroundColor: err != null ? Colors.red : AppColors.success,
                  ));
                  if (err != null) ref.read(authNotifierProvider.notifier).clearError();
                }
              },
              child: const Text('Create Account & Set Password'),
            ),
          ]),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Faculty f) {
    final nameCtrl  = TextEditingController(text: f.name);
    final emailCtrl = TextEditingController(text: f.email);
    final deptCtrl  = TextEditingController(text: f.department);
    final bldgCtrl  = TextEditingController(text: f.building);
    final cabinCtrl = TextEditingController(text: f.cabinId);
    final specCtrl  = TextEditingController(text: f.specialization ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Edit Faculty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _SheetField(ctrl: nameCtrl,  label: 'Full Name'),
            const SizedBox(height: 12),
            _SheetField(ctrl: emailCtrl, label: 'Email', type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _SheetField(ctrl: deptCtrl,  label: 'Department'),
            const SizedBox(height: 12),
            _SheetField(ctrl: bldgCtrl,  label: 'Building'),
            const SizedBox(height: 12),
            _SheetField(ctrl: cabinCtrl, label: 'Cabin / Room ID'),
            const SizedBox(height: 12),
            _SheetField(ctrl: specCtrl,  label: 'Specialization'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                ref.read(facultyNotifierProvider.notifier).updateFaculty(f.copyWith(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  building: bldgCtrl.text.trim(),
                  cabinId: cabinCtrl.text.trim(),
                  specialization: specCtrl.text.trim().isEmpty ? null : specCtrl.text.trim(),
                ));
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Faculty f) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text('Remove ${f.name} from the system?'),
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
            // Header
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(f.initials,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(f.department, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
            ]),
            const SizedBox(height: 20),
            // QR Code — explicit SizedBox fixes web rendering
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F172A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Faculty info below QR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.link_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(qrData, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
                ]),
                const SizedBox(height: 4),
                Text(f.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref, Faculty f) {
    showModalBottomSheet(
      context: context,
      // ✅ Use StatefulBuilder so the sheet rebuilds when status changes
      // Equivalent to React: local useState inside a component
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) {
          // Watch the live stream inside the sheet for instant feedback
          // ✅ Stream → equivalent to WebSocket: sheet reflects real-time state
          final liveAsync = ref.watch(facultyListProvider);
          final liveFaculty = liveAsync.whenData(
            (list) => list.where((f2) => f2.id == f.id).firstOrNull,
          ).value ?? f;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header with live status badge
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(liveFaculty.initials,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(liveFaculty.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  // Live status badge — updates instantly via stream
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: liveFaculty.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(liveFaculty.status.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: liveFaculty.status.color)),
                  ),
                ])),
              ]),
              const SizedBox(height: 20),
              const Text('Set Status',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              // ✅ Same animated chip grid as faculty dashboard
              Wrap(spacing: 8, runSpacing: 8, children: FacultyStatus.values
                  .where((s) => s != FacultyStatus.notAvailable)
                  .map((s) {
                final isActive = liveFaculty.status == s;
                return GestureDetector(
                  onTap: () {
                    // ✅ Future (Promise): async write, UI updates via stream automatically
                    ref.read(facultyNotifierProvider.notifier).updateStatus(f.id, s);
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${f.name} → ${s.label}'),
                      backgroundColor: s.color,
                    ));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? s.color : s.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: s.color.withValues(alpha: isActive ? 1.0 : 0.3),
                        width: isActive ? 1.5 : 1,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(color: s.color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(s.icon, size: 15, color: isActive ? Colors.white : s.color),
                      const SizedBox(width: 6),
                      Text(s.label, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : s.color,
                      )),
                      if (isActive) ...[
                        const SizedBox(width: 5),
                        Container(width: 6, height: 6,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      ],
                    ]),
                  ),
                );
              }).toList()),
              const SizedBox(height: 8),
            ]),
          );
        },
      ),
    );
  }
}

class _FacultyAdminCard extends ConsumerWidget {
  final Faculty faculty;
  final VoidCallback onEdit, onDelete, onQr, onStatus, onPassword;
  const _FacultyAdminCard({required this.faculty, required this.onEdit, required this.onDelete, required this.onQr, required this.onStatus, required this.onPassword});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Stream → DOM update: watch live list, derive this faculty's current state
    // Equivalent to: document.getElementById(id).textContent = newStatus
    final liveAsync = ref.watch(facultyListProvider);
    final live = liveAsync.whenData(
      (list) => list.where((f) => f.id == faculty.id).firstOrNull,
    ).value ?? faculty;

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Tappable avatar — admin can upload photo for any faculty
          FacultyAvatar(
            avatarBase64: live.avatarUrl,
            initials: live.initials,
            size: 52,
            borderRadius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(live.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('${live.department} · ${live.building}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            // ✅ This badge updates instantly when status changes — no reload needed
            _StatusBadge(live.status),
          ])),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ActionBtn(icon: Icons.swap_horiz_rounded, label: 'Status', onTap: onStatus),
          _ActionBtn(icon: Icons.qr_code_2_rounded,  label: 'QR Code', onTap: onQr),
          _ActionBtn(icon: Icons.edit_outlined,       label: 'Edit',    onTap: onEdit),
          _ActionBtn(icon: Icons.key_rounded,         label: 'Password', onTap: onPassword),
          _ActionBtn(icon: Icons.delete_outline_rounded, label: 'Delete', onTap: onDelete, color: AppColors.error),
        ]),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FacultyStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status.color)),
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
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;
  const _SheetField({required this.ctrl, required this.label, this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label),
    );
  }
}
