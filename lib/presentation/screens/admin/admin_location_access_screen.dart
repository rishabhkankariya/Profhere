import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/location_access_provider.dart';

class AdminLocationAccessScreen extends ConsumerWidget {
  final bool isEmbedded;
  const AdminLocationAccessScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isEmbedded) {
      // When embedded in admin dashboard, skip the Scaffold/AppBar
      return _LocationAccessBody();
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Location Access Management'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: _LocationAccessBody(),
      ),
    );
  }
}

class _LocationAccessBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: const TabBar(
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'All'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingTab(context, ref),
                _buildApprovedTab(context, ref),
                _buildAllTab(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab(BuildContext context, WidgetRef ref) {
    return ref.watch(allPendingAccessesProvider).when(
          data: (accesses) {
            if (accesses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No pending requests',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: accesses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final access = accesses[index];
                return _buildAccessCard(context, ref, access, showActions: true);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
  }

  Widget _buildApprovedTab(BuildContext context, WidgetRef ref) {
    return ref.watch(allPendingAccessesProvider).when(
          data: (allAccesses) {
            final approved = allAccesses
                .where((a) => a.isApproved)
                .toList();

            if (approved.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No approved accesses',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: approved.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final access = approved[index];
                return _buildAccessCard(context, ref, access, showActions: false);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
  }

  Widget _buildAllTab(BuildContext context, WidgetRef ref) {
    return ref.watch(allPendingAccessesProvider).when(
          data: (accesses) {
            if (accesses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No access records',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: accesses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final access = accesses[index];
                return _buildAccessCard(context, ref, access, showActions: false);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
  }

  Widget _buildAccessCard(
    BuildContext context,
    WidgetRef ref,
    dynamic access, {
    required bool showActions,
  }) {
    final statusColor = _getStatusColor(access.status);
    final statusIcon = _getStatusIcon(access.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        access.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        access.studentEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    access.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Faculty: ${access.facultyId}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Requested: ${_formatDate(access.requestedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (access.isApproved) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.router, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'NodeMCU: ${access.nodeMcuIpAddress}',
                          style: TextStyle(fontSize: 12, color: Colors.green[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(
                        context,
                        ref,
                        access.id,
                        access.studentName,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showApproveDialog(
                        context,
                        ref,
                        access.id,
                        access.studentName,
                      ),
                      child: const Text('Approve'),
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

  void _showApproveDialog(
    BuildContext context,
    WidgetRef ref,
    String accessId,
    String studentName,
  ) {
    final ipController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve $studentName\'s location access?'),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                hintText: '192.168.1.100',
                labelText: 'NodeMCU IP Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(locationAccessNotifierProvider.notifier)
                  .approveLocationAccess(
                    accessId: accessId,
                    nodeMcuIpAddress: ipController.text.trim(),
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Access approved')),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    String accessId,
    String studentName,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject $studentName\'s request?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(locationAccessNotifierProvider.notifier)
                  .rejectLocationAccess(
                    accessId: accessId,
                    reason: reasonController.text.trim(),
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request rejected')),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.index) {
      case 0: // pending
        return Colors.orange;
      case 1: // approved
        return Colors.green;
      case 2: // rejected
        return Colors.red;
      case 3: // revoked
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(dynamic status) {
    switch (status.index) {
      case 0: // pending
        return Icons.hourglass_empty;
      case 1: // approved
        return Icons.check_circle;
      case 2: // rejected
        return Icons.cancel;
      case 3: // revoked
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
