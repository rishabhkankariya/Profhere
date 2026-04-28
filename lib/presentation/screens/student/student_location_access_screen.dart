import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/faculty.dart';
import '../../providers/location_access_provider.dart';
import '../../providers/faculty_location_provider.dart';
import '../../providers/auth_provider.dart';

class StudentLocationAccessScreen extends ConsumerWidget {
  final Faculty faculty;
  const StudentLocationAccessScreen({Key? key, required this.faculty})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final studentId = user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Location'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFacultyCard(),
            const SizedBox(height: 20),
            _buildStatusSection(studentId, ref, context),
            const SizedBox(height: 20),
            _buildHowItWorks(),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(
            faculty.initials,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(faculty.name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(faculty.department,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            Text('${faculty.building} · ${faculty.cabinId}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }

  // ── Status section ────────────────────────────────────────────────────────
  Widget _buildStatusSection(String studentId, WidgetRef ref, BuildContext context) {
    return ref.watch(accessRequestsFromStudentProvider(studentId)).when(
          data: (requests) {
            final request = requests
                .where((r) => r.facultyId == faculty.id)
                .firstOrNull;

            if (request == null) return _buildNoRequestState(studentId, ref, context);
            
            // Check for revoked or rejected status first
            if (request.isRevoked || request.isRejected) {
              return _buildStatusCard(request, ref: ref, context: context);
            }
            
            // Then check for approved
            if (request.isApproved) {
              return _buildApprovedState(ref);
            }
            
            // Default to showing status card (pending, etc.)
            return _buildStatusCard(request, ref: ref, context: context);
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text('Error: $err')),
        );
  }

  // ── No request yet ────────────────────────────────────────────────────────
  Widget _buildNoRequestState(String studentId, WidgetRef ref, BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(Icons.location_on_outlined, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text('Request Location Access',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Ask ${faculty.name} to share their desk location with you.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            ref
                .read(locationAccessNotifierProvider.notifier)
                .requestLocationAccess(
                  facultyId: faculty.id,
                  studentId: studentId,
                  studentName: user?.name ?? '',
                  studentEmail: user?.email ?? '',
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request sent to faculty')),
            );
          },
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send Request'),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
    ]);
  }

  // ── Approved state — show faculty's real-time location ───────────────────
  Widget _buildApprovedState(WidgetRef ref) {
    return Column(children: [
      // ── Access approved badge ─────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.success.withOpacity(0.4), width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Location Access Granted',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success)),
                  Text(
                    'You can see ${faculty.name}\'s current location',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Faculty's real-time location ──────────────────────────────────────
      ref.watch(facultyLocationProvider(faculty.id)).when(
            data: (location) {
              if (location == null) {
                return _buildNoLocationData();
              }
              return _buildLocationCard(location);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => _buildErrorCard(err.toString()),
          ),
    ]);
  }

  // ── Location card showing faculty's current floor/area ────────────────────
  Widget _buildLocationCard(dynamic location) {
    final isStale = location.isStale;
    final isPresent = location.isPresent && !isStale;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPresent
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
          width: isPresent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPresent ? AppColors.success : AppColors.primary)
                .withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with status ────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPresent
                      ? AppColors.successBg
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPresent
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  color: isPresent ? AppColors.success : AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPresent ? 'Currently Present' : 'Not Available',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isPresent
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      'Updated ${location.timeAgo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Live indicator
              if (isPresent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (isPresent) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // ── Location details ──────────────────────────────────────────────
            _locationDetailRow(
              Icons.business_rounded,
              'Building',
              location.building,
            ),
            const SizedBox(height: 14),
            _locationDetailRow(
              Icons.layers_rounded,
              'Floor',
              location.floor,
              highlight: true,
            ),
            if (location.zone != null) ...[
              const SizedBox(height: 14),
              _locationDetailRow(
                Icons.place_rounded,
                'Zone / Area',
                location.zone!,
              ),
            ],
            if (location.cabinId != null) ...[
              const SizedBox(height: 14),
              _locationDetailRow(
                Icons.meeting_room_rounded,
                'Cabin / Room',
                location.cabinId!,
              ),
            ],

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── Auto-update info ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.autorenew_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Location updates automatically every 10-15 minutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isStale
                        ? Icons.signal_wifi_off_rounded
                        : Icons.person_off_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isStale
                          ? 'Location data is outdated. Faculty may have left or device is offline.'
                          : 'Faculty is currently not present at their desk.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationDetailRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: highlight ? AppColors.primary : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: highlight ? 16 : 14,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                  color: highlight ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoLocationData() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_searching_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Location Data',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Faculty hasn\'t shared their location yet. Please check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading location: $error',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending / Rejected / Revoked card ─────────────────────────────────────
  Widget _buildStatusCard(dynamic request, {WidgetRef? ref, BuildContext? context}) {
    final Color color;
    final IconData icon;
    final String label;
    final String desc;
    final bool canRequestAgain;

    switch (request.status.index) {
      case 0: // pending
        color = Colors.orange;
        icon = Icons.hourglass_empty_rounded;
        label = 'Pending Approval';
        desc = 'Waiting for ${faculty.name} to approve your request';
        canRequestAgain = false;
        break;
      case 2: // rejected
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        label = 'Request Rejected';
        desc = 'Rejected on ${_formatDate(request.rejectedAt)}';
        canRequestAgain = true;
        break;
      case 3: // revoked
        color = AppColors.error;
        icon = Icons.block_rounded;
        label = 'Access Revoked';
        desc = 'Revoked on ${_formatDate(request.revokedAt)}';
        canRequestAgain = true;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = request.status.label;
        desc = '';
        canRequestAgain = false;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: color)),
                      Text(desc,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ]),
              ),
            ]),
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reason: ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    Expanded(
                      child: Text(request.reason!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),
            ],
          ]),
        ),
        
        // Request Again button for rejected/revoked
        if (canRequestAgain && ref != null && context != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final user = ref.read(authNotifierProvider).user;
                ref
                    .read(locationAccessNotifierProvider.notifier)
                    .requestLocationAccess(
                      facultyId: faculty.id,
                      studentId: user?.id ?? '',
                      studentName: user?.name ?? '',
                      studentEmail: user?.email ?? '',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New request sent to faculty')),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Request Access Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How It Works',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _howTile(Icons.send_rounded, 'Request Access',
            'Ask the faculty to share their real-time location'),
        _howTile(Icons.hourglass_empty_rounded, 'Wait for Approval',
            'Faculty reviews and approves your request'),
        _howTile(Icons.location_on_rounded, 'View Location',
            'See which floor and area the faculty is currently at'),
        _howTile(Icons.autorenew_rounded, 'Auto-Updates',
            'Location refreshes automatically every 10-15 minutes'),
      ],
    );
  }

  Widget _howTile(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ]),
        ),
      ]),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}
