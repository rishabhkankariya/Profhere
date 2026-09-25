import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/follow_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/faculty_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/queue_provider.dart';
import '../providers/supabase_provider.dart';
import '../widgets/adaptive_back_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/premium_card.dart';
import 'faculty_profile_screen.dart';

class FacultyListScreen extends ConsumerWidget {
  const FacultyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBase,
      appBar: AppBar(
        leading: const AdaptiveBackButton(),
        title: const Text('Faculty Directory'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(facultyListProvider),
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.vibrantTeal),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const FacultyListScreenBody(),
    );
  }
}

class FacultyListScreenBody extends ConsumerStatefulWidget {
  const FacultyListScreenBody({super.key});

  @override
  ConsumerState<FacultyListScreenBody> createState() =>
      _FacultyListScreenBodyState();
}

class _FacultyListScreenBodyState extends ConsumerState<FacultyListScreenBody> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final supabaseClient = ref.watch(supabaseClientProvider);
    final facultyList = ref.watch(facultyListProvider);
    final currentUser = ref.watch(authStateProvider).asData?.value;
    final followEntries = ref.watch(followEntriesProvider);

    if (supabaseClient == null) {
      return const Center(child: Text('Supabase connectivity offline.'));
    }

    return facultyList.when(
      data: (facultyMembers) {
        final prioritizedFaculty = _buildVisibleFaculty(
          facultyMembers: facultyMembers,
          currentUser: currentUser,
          followEntries: followEntries,
          searchQuery: _searchQuery,
        );

        if (prioritizedFaculty.isEmpty && _searchQuery.isEmpty) {
          return const Center(child: Text('No active faculty found.'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: TextFormField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or specialty...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.vibrantTeal),
                  suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          onPressed: () => setState(() => _searchQuery = ''),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: prioritizedFaculty.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _FacultyTile(
                    faculty: prioritizedFaculty[index],
                    currentUser: currentUser,
                  );
                },
              ),
            ),
          ],
        );
      },
      error: (error, _) => Center(child: Text('Telemetry error: $error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  List<Faculty> _buildVisibleFaculty({
    required List<Faculty> facultyMembers,
    required AppUser? currentUser,
    required AsyncValue<List<FollowEntry>> followEntries,
    required String searchQuery,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final followedFacultyIds = followEntries.maybeWhen(
      data: (entries) => entries.map((entry) => entry.facultyId).toSet(),
      orElse: () => const <String>{},
    );

    final filteredFaculty = normalizedQuery.isEmpty
        ? facultyMembers
        : facultyMembers.where((faculty) {
            return faculty.name.toLowerCase().contains(normalizedQuery) ||
                faculty.department.toLowerCase().contains(normalizedQuery);
          }).toList();

    final sortedFaculty = [...filteredFaculty];
    sortedFaculty.sort((left, right) {
      if (currentUser?.role == UserRole.student) {
        final leftFollowed = followedFacultyIds.contains(left.id);
        final rightFollowed = followedFacultyIds.contains(right.id);
        if (leftFollowed != rightFollowed) return leftFollowed ? -1 : 1;
      }
      final leftAvailable = left.status.toLowerCase() == 'available';
      final rightAvailable = right.status.toLowerCase() == 'available';
      if (leftAvailable != rightAvailable) return leftAvailable ? -1 : 1;
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return sortedFaculty;
  }
}

class _FacultyTile extends ConsumerWidget {
  const _FacultyTile({required this.faculty, required this.currentUser});
  final Faculty faculty;
  final AppUser? currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStudent = currentUser?.role == UserRole.student;
    final isFollowing = ref.watch(isFollowingFacultyProvider(faculty.id));
    final isAvailable = faculty.status.toLowerCase() == 'available';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FacultyProfileScreen(faculty: faculty),
        ),
      ),
      child: PremiumCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'avatar-${faculty.id}',
                        child: Text(
                          faculty.name,
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.softGrey),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${faculty.department} • Cabin ${faculty.cabin}',
                        style: TextStyle(color: AppTheme.softGrey.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                _AvailabilityIndicator(isAvailable: isAvailable, status: faculty.status),
              ],
            ),
            if (isStudent) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _toggleFollow(context, ref),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.vibrantTeal.withValues(alpha: 0.3)),
                        foregroundColor: AppTheme.vibrantTeal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        isFollowing.maybeWhen(
                          data: (val) => val ? 'UNFOLLOW' : 'FOLLOW',
                          orElse: () => 'FOLLOW',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _joinQueue(context, ref),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'JOIN QUEUE',
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFollow(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(followControllerProvider).toggleFollow(faculty.id);
      if (context.mounted) AppToast.info(context, 'Director updated.');
    } catch (error) {
       if (context.mounted) AppToast.error(context, error.toString());
    }
  }

  Future<void> _joinQueue(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(queueControllerProvider).joinQueue(facultyId: faculty.id);
      if (context.mounted) AppToast.success(context, 'Queue entry established.');
    } catch (error) {
      if (context.mounted) AppToast.error(context, error.toString());
    }
  }
}

class _AvailabilityIndicator extends StatelessWidget {
  const _AvailabilityIndicator({required this.isAvailable, required this.status});
  final bool isAvailable;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppTheme.vibrantTeal : AppTheme.accentPeach;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    );
  }
}
