import '../../domain/entities/queue_entry.dart';

abstract final class QueueUtils {
  static QueueEntry? findNextWaitingEntry(List<QueueEntry> entries) {
    final waitingEntries =
        entries
            .where((entry) => entry.status == QueueEntryStatus.waiting)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    if (waitingEntries.isEmpty) {
      return null;
    }

    return waitingEntries.first;
  }

  static int waitingCount(List<QueueEntry> entries) {
    return entries
        .where((entry) => entry.status == QueueEntryStatus.waiting)
        .length;
  }
}
