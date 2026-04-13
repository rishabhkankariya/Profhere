import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/toast.dart';
import '../../../domain/entities/faculty.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/consultation.dart';
import '../../providers/faculty_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/prefs_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/faculty_avatar.dart';
import '../profile/edit_profile_screen.dart';

class FacultyListScreen extends ConsumerStatefulWidget {
  const FacultyListScreen({super.key});
  @override
  ConsumerState<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends ConsumerState<FacultyListScreen> {
  int _navIndex = 0;
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Exit the app
          // ignore: use_build_context_synchronously
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _navIndex, children: [
          _FacultyTab(onJoinQueue: _joinQueue),
          const _ProfileTab(),
        ]),
        bottomNavigationBar: _BottomNav(
          current: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }

  void _joinQueue(BuildContext ctx, Faculty faculty) {
    final purposeCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(faculty.initials,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(faculty.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
              Text(faculty.department, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: purposeCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Purpose of consultation',
              hintText: 'e.g. Project discussion, grade query',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (purposeCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final user = ref.read(authNotifierProvider).user;
              if (user == null) return;
              final result = await ref.read(consultationNotifierProvider.notifier).joinQueue(
                facultyId: faculty.id,
                studentId: user.id,
                studentName: user.name,
                purpose: purposeCtrl.text.trim(),
              );
              if (!ctx.mounted) return;
              if (result != null) {
                Toast.success(ctx, 'Joined queue — position #${result.position}, ~${result.waitTimeMinutes} min wait', title: 'Queue Joined');
              } else {
                final err = ref.read(consultationNotifierProvider).error;
                Toast.error(ctx, err?.toString().replaceAll('Exception: ', '') ?? 'Could not join queue', title: 'Queue Failed');
              }
            },
            child: const Text('Confirm & Join Queue'),
          ),
        ]),
      ),
    );
  }
}

// ─── Faculty Tab ─────────────────────────────────────────────────────────────

class _FacultyTab extends ConsumerWidget {
  final void Function(BuildContext, Faculty) onJoinQueue;
  const _FacultyTab({required this.onJoinQueue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultiesAsync = ref.watch(filteredFacultyProvider);
    final departments    = ref.watch(departmentsProvider);
    final selectedDept   = ref.watch(selectedDepartmentProvider);
    final subscribed     = ref.watch(subscriptionProvider);
    final prefs          = ref.watch(userPrefsProvider);

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, ref, prefs),
        SliverToBoxAdapter(child: _buildSearch(ref)),
        SliverToBoxAdapter(child: _buildDeptFilter(ref, departments, selectedDept)),
        facultiesAsync.when(
          data: (list) {
            final sorted = List<Faculty>.from(list);
            if (prefs.sort == FacultySort.subscribed) {
              sorted.sort((a, b) {
                final aSub = subscribed.contains(a.id) ? 0 : 1;
                final bSub = subscribed.contains(b.id) ? 0 : 1;
                if (aSub != bSub) return aSub.compareTo(bSub);
                return a.name.compareTo(b.name);
              });
            } else if (prefs.sort == FacultySort.statusFirst) {
              sorted.sort((a, b) => a.status.index.compareTo(b.status.index));
            } else {
              sorted.sort((a, b) => a.name.compareTo(b.name));
            }
            if (sorted.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('No faculty found', style: TextStyle(color: AppColors.textMuted))),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _FacultyCard(
                    faculty: sorted[i],
                    isSubscribed: subscribed.contains(sorted[i].id),
                    onTap: () => ctx.go('/faculty/${sorted[i].id}'),
                    onQueue: sorted[i].isAvailable ? () => onJoinQueue(ctx, sorted[i]) : null,
                    onSubscribe: () => ref.read(subscriptionProvider.notifier).toggle(sorted[i].id),
                  ),
                  childCount: sorted.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e'))),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, UserPrefs prefs) {
    final user = ref.watch(authNotifierProvider).user;
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      floating: true, snap: true, elevation: 0,
      scrolledUnderElevation: 0.5, shadowColor: AppColors.border, titleSpacing: 16,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hello, ${user?.name.split(' ').first ?? 'Student'}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const Text('Find your faculty', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
      ]),
      actions: [
        PopupMenuButton<FacultySort>(
          icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary, size: 22),
          onSelected: (s) => ref.read(userPrefsProvider.notifier).setSort(s),
          itemBuilder: (_) => [
            _sortItem(FacultySort.subscribed, 'Subscribed first', Icons.star_outline_rounded, prefs.sort),
            _sortItem(FacultySort.statusFirst, 'By availability', Icons.circle_outlined, prefs.sort),
            _sortItem(FacultySort.nameAsc, 'By name A-Z', Icons.sort_by_alpha_rounded, prefs.sort),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _UserAvatarChip(user: user),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ),
      ],
    );
  }

  PopupMenuItem<FacultySort> _sortItem(FacultySort val, String label, IconData icon, FacultySort current) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon, size: 18, color: current == val ? AppColors.primary : AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13,
          fontWeight: current == val ? FontWeight.w700 : FontWeight.w400,
          color: current == val ? AppColors.primary : AppColors.textPrimary)),
      ]),
    );
  }

  Widget _buildSearch(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        decoration: const InputDecoration(
          hintText: 'Search by name, department',
          prefixIcon: Icon(Icons.search_rounded, size: 20),
        ),
      ),
    );
  }

  Widget _buildDeptFilter(WidgetRef ref, List<String> depts, String? selected) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(label: 'All', active: selected == null,
              onTap: () => ref.read(selectedDepartmentProvider.notifier).state = null),
          ...depts.map((d) => _Chip(label: d, active: selected == d,
              onTap: () => ref.read(selectedDepartmentProvider.notifier).state = d)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _FacultyCard extends ConsumerWidget {
  final Faculty faculty;
  final bool isSubscribed;
  final VoidCallback onTap;
  final VoidCallback? onQueue;
  final VoidCallback onSubscribe;
  const _FacultyCard({required this.faculty, required this.isSubscribed,
      required this.onTap, this.onQueue, required this.onSubscribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authNotifierProvider).user?.id ?? '';
    final queueAsync = ref.watch(consultationsByFacultyProvider(faculty.id));

    final waitingCount = queueAsync.whenData(
      (list) => list.where((c) => c.status == ConsultationStatus.pending).length,
    ).value ?? 0;

    // My active request for this faculty
    final myRequest = queueAsync.whenData((list) => list.where((c) =>
        c.studentId == currentUserId &&
        (c.status == ConsultationStatus.pending ||
            c.status == ConsultationStatus.inProgress)).firstOrNull).value;

    final isInQueue = myRequest != null;
    final isActive  = myRequest?.status == ConsultationStatus.inProgress;

    // Border highlights: in-queue > subscribed > default
    final borderColor = isInQueue
        ? (isActive ? AppColors.success.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.4))
        : (isSubscribed ? AppColors.warning.withValues(alpha: 0.4) : AppColors.border);
    final borderWidth = isInQueue || isSubscribed ? 1.5 : 1.0;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Avatar
              Stack(children: [
                FacultyAvatar(
                  avatarBase64: faculty.avatarUrl,
                  initials: faculty.initials,
                  size: 50,
                  borderRadius: 14,
                ),
                Positioned(right: 0, bottom: 0,
                  child: Container(width: 13, height: 13,
                    decoration: BoxDecoration(color: faculty.status.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2)))),
                if (isSubscribed)
                  Positioned(right: -2, top: -2,
                    child: Container(width: 16, height: 16,
                      decoration: BoxDecoration(color: AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5)),
                      child: const Icon(Icons.star_rounded, size: 9, color: Colors.white))),
              ]),
              const SizedBox(width: 12),
              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(faculty.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis, maxLines: 1),
                const SizedBox(height: 2),
                Row(children: [
                  Flexible(
                    child: Text(faculty.department, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  _StatusBadge(faculty.status),
                ]),
                if (waitingCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(6)),
                    child: Text('$waitingCount waiting',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning))),
                ],
              ])),
              const SizedBox(width: 8),
              // Right actions
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                // Star subscription button
                GestureDetector(
                  onTap: onSubscribe,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isSubscribed ? AppColors.warning.withValues(alpha: 0.12) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(isSubscribed ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 18, color: isSubscribed ? AppColors.warning : AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                // Queue button or status indicator
                if (isInQueue)
                  // Already in queue — show position badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.successBg : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? AppColors.success.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        isActive ? Icons.play_circle_rounded : Icons.queue_rounded,
                        size: 14,
                        color: isActive ? AppColors.success : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Active' : '#${myRequest.position}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ]),
                  )
                else if (onQueue != null)
                  // Show Queue button if available
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onQueue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Queue'),
                    ),
                  ),
              ]),
            ]),
            // ── "You're in queue" banner shown below the card row ──────────
            if (isInQueue) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.successBg : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(
                    isActive ? Icons.play_circle_outline_rounded : Icons.access_time_rounded,
                    size: 14,
                    color: isActive ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    isActive
                        ? 'Your consultation is in progress — go to the cabin'
                        : 'You are #${myRequest.position} in queue · ~${myRequest.waitTimeMinutes} min wait',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : AppColors.primary,
                    ),
                  )),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FacultyStatus status;
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status.color)),
    );
  }
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final subscribed = ref.watch(subscriptionProvider);
    final prefs = ref.watch(userPrefsProvider);
    final facultiesAsync = ref.watch(facultyListProvider);

    final subscribedFaculties = facultiesAsync.whenData(
      (list) => list.where((f) => subscribed.contains(f.id)).toList(),
    ).value ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _ProfileCard(user: user),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _StatTile(label: 'Subscribed', value: '${subscribed.length}', icon: Icons.star_rounded, color: AppColors.warning)),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(label: 'Faculty', value: '${facultiesAsync.value?.length ?? 0}', icon: Icons.people_alt_outlined, color: AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(label: 'Available', value: '${facultiesAsync.value?.where((f) => f.isAvailable).length ?? 0}', icon: Icons.check_circle_outline_rounded, color: AppColors.success)),
          ]),
          const SizedBox(height: 20),
          if (subscribedFaculties.isNotEmpty) ...[
            _SectionTitle(title: 'Subscribed Faculty', count: subscribedFaculties.length),
            const SizedBox(height: 10),
            ...subscribedFaculties.map((f) => _SubscribedRow(
              faculty: f,
              onTap: () => context.go('/faculty/${f.id}'),
              onUnsubscribe: () => ref.read(subscriptionProvider.notifier).toggle(f.id),
            )),
            const SizedBox(height: 20),
          ],
          _SectionTitle(title: 'Settings'),
          const SizedBox(height: 10),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              subtitle: 'Alerts when subscribed faculty is available',
              trailing: Switch(
                value: prefs.notificationsEnabled,
                onChanged: (_) => ref.read(userPrefsProvider.notifier).toggleNotifications(),
                activeTrackColor: AppColors.primary,
              ),
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.sort_rounded,
              label: 'Sort Order',
              subtitle: _sortLabel(prefs.sort),
              onTap: () => _showSortPicker(context, ref, prefs.sort),
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.forum_outlined,
              label: 'Community Chat',
              subtitle: 'Share ideas with students & faculty',
              onTap: () => context.go(AppRoutes.community),
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: _communityModeIcon(prefs.communityMode),
              label: 'Community Mode',
              subtitle: _communityModeLabel(prefs.communityMode),
              iconColor: _communityModeColor(prefs.communityMode),
              onTap: () => _showCommunityModePicker(context, ref, prefs.communityMode),
            ),
          ]),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Account'),
          const SizedBox(height: 10),
          _SettingsCard(children: [
            if (user?.studentCode != null)
              _SettingsTile(icon: Icons.badge_outlined, label: 'Roll No / Enrollment', subtitle: user!.studentCode!),
            if (user?.phoneNumber != null) ...[
              const Divider(height: 1),
              _SettingsTile(icon: Icons.phone_outlined, label: 'Phone Number', subtitle: user!.phoneNumber!),
            ],
            if (user?.yearOfStudy != null) ...[
              const Divider(height: 1),
              _SettingsTile(icon: Icons.school_outlined, label: 'Year of Study', subtitle: 'Year ${user!.yearOfStudy}'),
            ],
            if (user?.department != null) ...[
              const Divider(height: 1),
              _SettingsTile(icon: Icons.business_outlined, label: 'Department', subtitle: user!.department!),
            ],
            const Divider(height: 1),
            _SettingsTile(icon: Icons.calendar_today_outlined, label: 'Member Since', subtitle: _formatDate(user?.createdAt)),
          ]),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Danger Zone'),
          const SizedBox(height: 10),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              label: 'Clear Subscriptions',
              subtitle: 'Remove all subscribed faculty',
              iconColor: AppColors.warning,
              onTap: () => _confirmClearSubs(context, ref),
            ),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  String _sortLabel(FacultySort s) {
    switch (s) {
      case FacultySort.subscribed:  return 'Subscribed first';
      case FacultySort.statusFirst: return 'By availability';
      case FacultySort.nameAsc:     return 'By name (A-Z)';
    }
  }

  String _communityModeLabel(CommunityMode m) {
    switch (m) {
      case CommunityMode.public:    return 'Public — profile image shown';
      case CommunityMode.private:   return 'Private — name with initial letter';
      case CommunityMode.anonymous: return 'Anonymous — name with people icon';
    }
  }

  IconData _communityModeIcon(CommunityMode m) {
    switch (m) {
      case CommunityMode.public:    return Icons.photo_outlined;
      case CommunityMode.private:   return Icons.person_outline_rounded;
      case CommunityMode.anonymous: return Icons.people_outline_rounded;
    }
  }

  Color _communityModeColor(CommunityMode m) {
    switch (m) {
      case CommunityMode.public:    return AppColors.primary;
      case CommunityMode.private:   return AppColors.success;
      case CommunityMode.anonymous: return AppColors.textMuted;
    }
  }

  void _showCommunityModePicker(BuildContext context, WidgetRef ref, CommunityMode current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Community Chat Mode', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Choose how you appear in Community Chat', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          ...CommunityMode.values.map((m) {
            final active = m == current;
            final labels = ['Public', 'Private', 'Anonymous'];
            final subs   = ['Your profile image is shown', 'Your name is shown with name letter photo', 'You appear with your name and people icon'];
            final icons  = [Icons.photo_outlined, Icons.person_outline_rounded, Icons.people_outline_rounded];
            final colors = [AppColors.primary, AppColors.success, AppColors.textMuted];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: colors[m.index].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icons[m.index], color: colors[m.index], size: 20)),
              title: Text(labels[m.index], style: TextStyle(fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? colors[m.index] : AppColors.textPrimary)),
              subtitle: Text(subs[m.index], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              trailing: active ? Icon(Icons.check_circle_rounded, color: colors[m.index], size: 20) : null,
              onTap: () {
                ref.read(userPrefsProvider.notifier).setCommunityMode(m);
                Navigator.pop(context);
              },
            );
          }),
        ]),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _showSortPicker(BuildContext context, WidgetRef ref, FacultySort current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sort Faculty By', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...FacultySort.values.map((s) {
            final labels = ['Subscribed first', 'By availability', 'By name (A-Z)'];
            final icons  = [Icons.star_outline_rounded, Icons.circle_outlined, Icons.sort_by_alpha_rounded];
            final active = s == current;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icons[s.index], color: active ? AppColors.primary : AppColors.textMuted, size: 20),
              title: Text(labels[s.index], style: TextStyle(fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? AppColors.primary : AppColors.textPrimary)),
              trailing: active ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
              onTap: () { ref.read(userPrefsProvider.notifier).setSort(s); Navigator.pop(context); },
            );
          }),
        ]),
      ),
    );
  }

  void _confirmClearSubs(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Subscriptions'),
        content: const Text('Remove all subscribed faculty from your list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final subs = List<String>.from(ref.read(subscriptionProvider));
              for (final id in subs) { ref.read(subscriptionProvider.notifier).toggle(id); }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final User? user;
  const _ProfileCard({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Row(children: [
          // Tappable avatar — student can upload their own photo
          GestureDetector(
            onTap: () => _pickPhoto(context, ref, prefs),
            child: Stack(children: [
              _buildAvatar(prefs),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: AppColors.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?.name ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 3),
            Text(user?.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(user?.role.label ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
          ])),
          // Edit profile button
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
            tooltip: 'Edit Profile',
          ),
        ]),
        const SizedBox(height: 16),
        // Sign out button directly on card
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white70),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white70, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white30),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAvatar(UserPrefs prefs) {
    if (prefs.avatarBase64 != null && prefs.avatarBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(prefs.avatarBase64!);
        return CircleAvatar(
          radius: 30,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      child: Text(user?.initials ?? '?',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  void _pickPhoto(BuildContext context, WidgetRef ref, UserPrefs prefs) {
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
              final ok = await ref.read(userPrefsProvider.notifier).pickAvatar();
              if (ok && context.mounted) {
                Toast.success(context, 'Profile photo updated');
              }
            },
          ),
          if (prefs.avatarBase64 != null && prefs.avatarBase64!.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20)),
              title: const Text('Remove photo', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(userPrefsProvider.notifier).removeAvatar();
              },
            ),
        ]),
      ),
    );
  }
}

class _SubscribedRow extends StatelessWidget {
  final Faculty faculty;
  final VoidCallback onTap, onUnsubscribe;
  const _SubscribedRow({required this.faculty, required this.onTap, required this.onUnsubscribe});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(faculty.initials, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(faculty.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(faculty.department, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: faculty.status.color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(faculty.status.label, style: TextStyle(fontSize: 11, color: faculty.status.color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            GestureDetector(onTap: onUnsubscribe, child: const Icon(Icons.star_rounded, size: 18, color: AppColors.warning)),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionTitle({required this.title, this.count});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
      if (count != null) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))),
      ],
    ]);
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  const _SettingsTile({required this.icon, required this.label, this.subtitle, this.trailing, this.onTap, this.iconColor});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: (iconColor ?? AppColors.primary).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
          if (trailing != null) trailing!
          else if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }
}

// ─── User Avatar Chip (app bar) ───────────────────────────────────────────────

class _UserAvatarChip extends ConsumerWidget {
  final User? user;
  const _UserAvatarChip({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);

    // Public mode → show profile image
    if (prefs.communityMode == CommunityMode.public &&
        prefs.avatarBase64 != null && prefs.avatarBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(prefs.avatarBase64!);
        return CircleAvatar(radius: 17, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }

    // Private mode → show name with initial letter
    if (prefs.communityMode == CommunityMode.private) {
      return CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.primaryLight,
        child: Text(user?.initials ?? '?',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
      );
    }

    // Anonymous mode → show name with people icon
    return CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.surfaceElevated,
      child: const Icon(Icons.people_outline_rounded, size: 18, color: AppColors.textMuted),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _NavItem(icon: Icons.people_alt_outlined, activeIcon: Icons.people_alt_rounded, label: 'Faculty', active: current == 0, onTap: () => onTap(0)),
            _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', active: current == 1, onTap: () => onTap(1)),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? activeIcon : icon, size: 24, color: active ? AppColors.primary : AppColors.textMuted),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.textMuted)),
        ]),
      ),
    );
  }
}
