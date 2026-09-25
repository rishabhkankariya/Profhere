import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/queue_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/faculty_provider.dart';
import '../providers/faculty_profile_provider.dart';
import '../providers/queue_provider.dart';
import '../providers/timetable_import_provider.dart';
import '../widgets/adaptive_back_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/premium_card.dart';
import 'faculty_list_screen.dart';

class FacultyDashboardScreen extends ConsumerStatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  ConsumerState<FacultyDashboardScreen> createState() =>
      _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState
    extends ConsumerState<FacultyDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cabinController = TextEditingController();
  String? _loadedFacultyId;
  bool _isSaving = false;
  bool _isImporting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cabinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facultyProfile = ref.watch(currentFacultyProfileProvider);
    final facultyListState = ref.watch(facultyListProvider);

    return Scaffold(
      backgroundColor: AppTheme.obsidianBase,
      appBar: AppBar(
        leading: const AdaptiveBackButton(),
        title: const Text('Faculty Portal'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppTheme.obsidianLayer2,
              child: IconButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 20, color: AppTheme.accentPeach),
              ),
            ),
          ),
        ],
      ),
      body: facultyProfile.when(
        data: (faculty) {
          if (faculty != null && _loadedFacultyId != faculty.id) {
            _loadedFacultyId = faculty.id;
            _nameController.text = faculty.name;
            _cabinController.text = faculty.cabin;
          }

          return Stack(
            children: [
              Positioned(
                top: -50,
                right: -30,
                child: _GlowOrb(size: 200, color: AppTheme.electricTeal.withValues(alpha: 0.1)),
              ),
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile Section (Hero)
                  if (faculty != null) ...[
                    _buildFacultyHero(faculty, facultyListState),
                    const SizedBox(height: 24),
                    _StatusUpdateSection(
                      currentStatus: faculty.status,
                      onStatusUpdate: (status) => _updateStatus(faculty.id, status),
                    ),
                  ] else
                    const PremiumCard(
                      child: Text('Please create your faculty profile to begin.'),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  if (faculty != null) ...[
                    // Queue Snapshot (New Feature)
                    _SectionHeader(title: 'Queue Control', subtitle: 'Live student consultation management'),
                    const SizedBox(height: 16),
                    _FacultyQueueSection(facultyId: faculty.id),
                    
                    const SizedBox(height: 40),

                    // Utility Tools
                    _SectionHeader(title: 'Portal Utilities', subtitle: 'Import and manage campus data'),
                    const SizedBox(height: 16),
                    _buildTimetableImport(context),
                    
                    const SizedBox(height: 40),

                    // Profile Settings
                    _SectionHeader(title: 'Identity Settings', subtitle: 'Update your official campus presence'),
                    const SizedBox(height: 16),
                    _FacultyProfileSection(
                      formKey: _formKey,
                      nameController: _nameController,
                      cabinController: _cabinController,
                      isSaving: _isSaving,
                      onSave: () => _saveProfile(faculty.id),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Collective Overview
                  _SectionHeader(title: 'Department Reach', subtitle: 'View surrounding faculty presence'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.obsidianLayer1,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    height: 500,
                    clipBehavior: Clip.antiAlias,
                    child: const FacultyListScreenBody(),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Profile expansion failed.\n$error')),
      ),
    );
  }

  Widget _buildFacultyHero(Faculty faculty, AsyncValue<List<Faculty>> facultyListState) {
    final status = _resolveAvailabilityStatus(faculty: faculty, facultyListState: facultyListState);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBadge(status: status),
              const Spacer(),
              Text('PORTAL ACCESS', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            faculty.name,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.softGrey,
              letterSpacing: -0.8,
            ),
          ),
          Text(
            'Cabin ${faculty.cabin} • ${faculty.department}',
            style: TextStyle(
              color: AppTheme.softGrey.withValues(alpha: 0.5),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: StatPill(label: 'Today Sessions', value: '14', color: AppTheme.vibrantTeal)),
              const SizedBox(width: 12),
              Expanded(child: StatPill(label: 'Peak Hour', value: '11:30 AM', color: AppTheme.accentPeach)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableImport(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart_outlined, color: AppTheme.vibrantTeal, size: 24),
              const SizedBox(width: 12),
              Text('TIMETABLE INGESTOR', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sync your weekly schedule via Excel. Our curator will automatically update your status based on these slots.',
            style: TextStyle(color: AppTheme.softGrey.withValues(alpha: 0.5), height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isImporting ? null : _importTimetable,
            icon: Icon(_isImporting ? Icons.refresh_rounded : Icons.file_upload_outlined, size: 20),
            label: Text(_isImporting ? 'Processing Architecture...' : 'Upload Scheduler Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile(String facultyId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(facultyProfileControllerProvider).updateProfile(
        facultyId: facultyId,
        name: _nameController.text.trim(),
        cabin: _cabinController.text.trim(),
      );
      if (mounted) AppToast.success(context, 'Global metadata updated.');
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _importTimetable() async {
    setState(() => _isImporting = true);
    try {
      final result = await ref.read(timetableImportControllerProvider.notifier).pickAndImport();
      ref.invalidate(facultyListProvider);
      if (mounted) {
        final message = result.errors.isEmpty
            ? 'Success: ${result.importedCount} entries mapped.'
            : 'Mapped ${result.importedCount} entries with ${result.errors.length} alerts.';
        AppToast.success(context, message);
      }
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _updateStatus(String facultyId, String status) async {
    try {
      await ref.read(facultyProfileControllerProvider).updateStatus(
            facultyId: facultyId,
            status: status,
          );
      if (mounted) AppToast.success(context, 'Availability status synchronized.');
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    }
  }

  String _resolveAvailabilityStatus({
    required Faculty faculty,
    required AsyncValue<List<Faculty>> facultyListState,
  }) {
    return facultyListState.maybeWhen(
      data: (facultyList) {
        final matchedFaculty = facultyList
            .cast<Faculty?>()
            .firstWhere((item) => item?.id == faculty.id, orElse: () => null);
        return matchedFaculty?.status ?? 'Offline';
      },
      orElse: () => 'Syncing...',
    );
  }
}

class _FacultyQueueSection extends ConsumerWidget {
  const _FacultyQueueSection({required this.facultyId});
  final String facultyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(facultyQueueProvider(facultyId));
    final queueSummaryState = ref.watch(queueSummaryProvider(facultyId));

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          queueSummaryState.when(
            data: (summary) => _QueueSummarySnapshot(
              summary: summary,
              onCallNext: () => _callNextStudent(context, ref),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => Text('Failed to load queue telemetry.'),
          ),
          const SizedBox(height: 24),
          queueState.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('CURATION QUEUE EMPTY', style: Theme.of(context).textTheme.labelSmall),
                  ),
                );
              }
              return Column(
                children: entries.map((entry) => _QueueEntryTile(entry: entry, facultyId: facultyId)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Text('Telemetry disconnect.'),
          ),
        ],
      ),
    );
  }

  Future<void> _callNextStudent(BuildContext context, WidgetRef ref) async {
    try {
      final entry = await ref.read(queueControllerProvider).callNextStudent(facultyId);
      if (context.mounted) {
        AppToast.info(context, entry == null ? 'No sessions pending.' : 'Next curator target: ${entry.studentName ?? entry.studentId}.');
      }
    } catch (error) {
      if (context.mounted) AppToast.error(context, error.toString());
    }
  }
}

class _QueueSummarySnapshot extends StatelessWidget {
  const _QueueSummarySnapshot({required this.summary, required this.onCallNext});
  final QueueSummary summary;
  final VoidCallback onCallNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NOW CURATING', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.vibrantTeal)),
                const SizedBox(height: 4),
                Text(
                  summary.nowServing?.studentName ?? 'IDLE',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.softGrey),
                ),
              ],
            ),
            IconButton.filled(
              onPressed: onCallNext,
              icon: const Icon(Icons.skip_next_rounded),
              style: IconButton.styleFrom(backgroundColor: AppTheme.electricTeal, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _MiniStat(label: 'WAITING', value: '${summary.waitingCount}'),
            const SizedBox(width: 24),
            _MiniStat(label: 'SESSIONS', value: '${summary.totalEntries}'),
          ],
        ),
      ],
    );
  }
}

class _QueueEntryTile extends ConsumerWidget {
  const _QueueEntryTile({required this.entry, required this.facultyId});
  final QueueEntry entry;
  final String facultyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.obsidianLayer1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.obsidianLayer3,
            child: Text('${entry.position}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.softGrey)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.studentName ?? entry.studentId, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.softGrey)),
                Text(entry.status.value.toUpperCase(), style: TextStyle(fontSize: 10, color: AppTheme.softGrey.withValues(alpha: 0.4), letterSpacing: 1.1)),
              ],
            ),
          ),
          if (entry.status != QueueEntryStatus.completed)
            IconButton(
              onPressed: () => _updateStatus(context, ref, entry, QueueEntryStatus.completed),
              icon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.vibrantTeal, size: 20),
            ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, QueueEntry entry, QueueEntryStatus status) async {
    try {
      await ref.read(queueControllerProvider).updateQueueStatus(facultyId: facultyId, queueEntryId: entry.id, status: status);
    } catch (error) {
      if (context.mounted) AppToast.error(context, error.toString());
    }
  }
}

class _FacultyProfileSection extends StatelessWidget {
  const _FacultyProfileSection({
    required this.formKey,
    required this.nameController,
    required this.cabinController,
    required this.isSaving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController cabinController;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldLabel(label: 'DISPLAY NAME'),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Prof. Dr. Curator'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Name is mandatory' : null,
            ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'OFFICIAL CABIN ID'),
            const SizedBox(height: 8),
            TextFormField(
              controller: cabinController,
              decoration: const InputDecoration(hintText: 'B-Block 402'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Cabin link is mandatory' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isSaving ? null : onSave,
              child: Text(isSaving ? 'Synchronizing Profile...' : 'Update Authority Persona'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'available':
        color = AppTheme.vibrantTeal;
        icon = Icons.check_circle_rounded;
        break;
      case 'away':
        color = AppTheme.accentPeach;
        icon = Icons.access_time_filled_rounded;
        break;
      case 'busy':
        color = Colors.redAccent;
        icon = Icons.do_not_disturb_on_rounded;
        break;
      case 'on_break':
        color = Colors.orangeAccent;
        icon = Icons.coffee_rounded;
        break;
      default:
        color = AppTheme.softGrey;
        icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusUpdateSection extends StatelessWidget {
  const _StatusUpdateSection({
    required this.currentStatus,
    required this.onStatusUpdate,
  });

  final String currentStatus;
  final Function(String) onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPDATE CURRENT STATUS',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatusButton(
                label: 'Available',
                status: 'available',
                icon: Icons.check_circle_rounded,
                color: AppTheme.vibrantTeal,
                isSelected: currentStatus.toLowerCase() == 'available',
                onTap: () => onStatusUpdate('available'),
              ),
              const SizedBox(width: 8),
              _StatusButton(
                label: 'Away',
                status: 'away',
                icon: Icons.access_time_rounded,
                color: AppTheme.accentPeach,
                isSelected: currentStatus.toLowerCase() == 'away',
                onTap: () => onStatusUpdate('away'),
              ),
              const SizedBox(width: 8),
              _StatusButton(
                label: 'Busy',
                status: 'busy',
                icon: Icons.block_flipped,
                color: Colors.redAccent,
                isSelected: currentStatus.toLowerCase() == 'busy',
                onTap: () => onStatusUpdate('busy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.status,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String status;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : AppTheme.obsidianLayer2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppTheme.softGrey, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : AppTheme.softGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.electricTeal, letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.softGrey)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.softGrey, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(color: AppTheme.softGrey.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: Theme.of(context).textTheme.labelMedium);
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])));
}
