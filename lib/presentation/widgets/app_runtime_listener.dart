import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/notification_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/queue_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/queue_provider.dart';

class AppRuntimeListener extends ConsumerStatefulWidget {
  const AppRuntimeListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppRuntimeListener> createState() => _AppRuntimeListenerState();
}

class _AppRuntimeListenerState extends ConsumerState<AppRuntimeListener> {
  Map<String, String> _facultyStatusById = const <String, String>{};
  Map<String, QueueEntryStatus> _studentQueueStatusById =
      const <String, QueueEntryStatus>{};

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Faculty>>>(followedFacultyProvider, (
      previous,
      next,
    ) {
      final currentUser = ref.read(authStateProvider).asData?.value;
      if (currentUser?.role != UserRole.student) {
        return;
      }

      next.whenData((facultyList) {
        final latestMap = <String, String>{
          for (final faculty in facultyList) faculty.id: faculty.status,
        };

        for (final faculty in facultyList) {
          final previousStatus = _facultyStatusById[faculty.id];
          if (previousStatus != null &&
              previousStatus != faculty.status &&
              faculty.status == 'Available') {
            NotificationService.showNotification(
              id: faculty.id.hashCode,
              title: 'Faculty Available',
              body: '${faculty.name} is now available.',
            );
          }
        }

        _facultyStatusById = latestMap;
      });
    });

    ref.listen<AsyncValue<List<QueueEntry>>>(studentQueueProvider, (
      previous,
      next,
    ) {
      final currentUser = ref.read(authStateProvider).asData?.value;
      if (currentUser?.role != UserRole.student) {
        return;
      }

      next.whenData((entries) {
        final latestMap = <String, QueueEntryStatus>{
          for (final entry in entries) entry.id: entry.status,
        };

        for (final entry in entries) {
          final previousStatus = _studentQueueStatusById[entry.id];
          if (previousStatus != entry.status &&
              entry.status == QueueEntryStatus.called) {
            NotificationService.showNotification(
              id: entry.id.hashCode,
              title: 'Queue Update',
              body: 'You are next in queue.',
            );
          }
        }

        _studentQueueStatusById = latestMap;
      });
    });

    return widget.child;
  }
}
