import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/follow_entry.dart';
import '../../domain/entities/queue_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/queue_provider.dart';
import '../widgets/adaptive_back_button.dart';
import '../widgets/premium_card.dart';
import 'faculty_list_screen.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).asData?.value;
    final followEntries = ref.watch(followEntriesProvider);
    final queueEntries = ref.watch(studentQueueProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.obsidianBase,
      appBar: AppBar(
        leading: const AdaptiveBackButton(),
        title: const Text('Campus Terminal'),
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
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -50,
            child: _GlowOrb(size: 300, color: AppTheme.electricTeal.withValues(alpha: 0.1)),
          ),
          
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Hero Header
                _buildHero(context, currentUser, followEntries, queueEntries),
                const SizedBox(height: 32),

                // Live Activity Indicators
                _SectionTitle(title: 'Live Activity', subtitle: 'Real-time academic updates'),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActivityCard(
                        context,
                        'Current Queue',
                        _getQueueCountString(queueEntries),
                        Icons.hourglass_empty_rounded,
                        AppTheme.electricTeal,
                      ),
                      const SizedBox(width: 12),
                      _buildActivityCard(
                        context,
                        'Wait Time',
                        '~12 mins',
                        Icons.timer_outlined,
                        AppTheme.vibrantTeal,
                      ),
                      const SizedBox(width: 12),
                      _buildActivityCard(
                        context,
                        'Active Labs',
                        '4 Open',
                        Icons.memory_rounded,
                        AppTheme.accentPeach,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // Faculty Feed
                _SectionTitle(title: 'Faculty Feed', subtitle: 'Browse availability and expertise'),
                const SizedBox(height: 16),
                
                // Embedded Faculty List with a container for design consistency
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianLayer1,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  height: 600,
                  clipBehavior: Clip.antiAlias,
                  child: const FacultyListScreenBody(),
                ),
                
                const SizedBox(height: 32),
                
                // Bulletin Feature (New Feature)
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppTheme.vibrantTeal),
                          const SizedBox(width: 12),
                          Text('CAMPUS NEWS', style: theme.textTheme.labelMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Department of AI & ML has updated the consultation hours for the upcoming semester. Please check the profile pages.',
                        style: GoogleFonts.inter(
                          color: AppTheme.softGrey.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context, 
    AppUser? user, 
    AsyncValue<List<FollowEntry>> followEntries, 
    AsyncValue<List<QueueEntry>> queueEntries,
  ) {
    final name = user?.name ?? 'Researcher';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return PremiumCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.vibrantTeal, AppTheme.electricTeal],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CORE IDENTITY', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.softGrey),
                    ),
                    Text(
                      user?.email ?? 'No email linked',
                      style: TextStyle(color: AppTheme.softGrey.withValues(alpha: 0.4), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: StatPill(
                  label: 'Followings', 
                  value: followEntries.maybeWhen(
                    data: (entries) => entries.length.toString(),
                    orElse: () => '0',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatPill(
                  label: 'Active Task', 
                  value: _getQueueCountString(queueEntries), 
                  color: AppTheme.vibrantTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.obsidianLayer2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.softGrey),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: AppTheme.softGrey.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getQueueCountString(AsyncValue<List<QueueEntry>> queueEntries) {
    return queueEntries.maybeWhen(
      data: (entries) => entries
          .where((entry) => entry.status != QueueEntryStatus.completed)
          .length
          .toString(),
      orElse: () => '--',
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppTheme.softGrey,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.softGrey.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
