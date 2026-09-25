import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/faculty.dart';
import '../providers/queue_provider.dart';
import '../widgets/adaptive_back_button.dart';
import '../widgets/app_toast.dart';

class FacultyProfileScreen extends ConsumerWidget {
  const FacultyProfileScreen({super.key, required this.faculty});
  final Faculty faculty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = faculty.status.toLowerCase() == 'available';

    return Scaffold(
      backgroundColor: AppTheme.obsidianBase,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: const AdaptiveBackButton(),
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTheme.obsidianLayer1, AppTheme.obsidianBase],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Hero(
                          tag: 'avatar-${faculty.id}',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppTheme.vibrantTeal, AppTheme.electricTeal],
                              ),
                            ),
                            child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          faculty.name,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.softGrey,
                          ),
                        ),
                        Text(
                          faculty.department,
                          style: TextStyle(color: AppTheme.softGrey.withValues(alpha: 0.5), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Availability Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAvailabilityBadge(isAvailable, faculty.status),
                    Text(
                      'Cabin ${faculty.cabin}',
                      style: const TextStyle(color: AppTheme.softGrey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Research Focus
                _SectionTitle(title: 'BIO & EXPERTISE'),
                const SizedBox(height: 12),
                Text(
                  'Expert in Intelligent Systems, Cloud Computing, and Scalable Architectures. Currently overseeing several campus digital initiatives.',
                  style: GoogleFonts.inter(color: AppTheme.softGrey.withValues(alpha: 0.7), height: 1.6),
                ),
                const SizedBox(height: 32),

                // Timelines (Mocked)
                _SectionTitle(title: 'CONSULTATION WINDOWS (TODAY)'),
                const SizedBox(height: 12),
                _buildTimelineSlot('AVAILABLE', '10:00 AM - 12:30 PM', AppTheme.vibrantTeal),
                _buildTimelineSlot('IN LECTURE', '01:00 PM - 03:00 PM', AppTheme.accentPeach.withValues(alpha: 0.5)),
                _buildTimelineSlot('AVAILABLE', '03:30 PM - 05:00 PM', AppTheme.vibrantTeal),
                
                const SizedBox(height: 48),

                // Join Queue Action
                ElevatedButton(
                  onPressed: () => _joinQueue(context, ref),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: const Text('ESTABLISH CONSULTATION REQUEST'),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(bool isAvailable, String status) {
    final color = isAvailable ? AppTheme.vibrantTeal : AppTheme.accentPeach;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11),
      ),
    );
  }

  Widget _buildTimelineSlot(String label, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.obsidianLayer2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
              Text(time, style: const TextStyle(color: AppTheme.softGrey, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _joinQueue(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(queueControllerProvider).joinQueue(facultyId: faculty.id);
      if (context.mounted) AppToast.success(context, 'Successfully linked to curator queue.');
    } catch (error) {
      if (context.mounted) AppToast.error(context, error.toString());
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppTheme.vibrantTeal,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
