import 'package:flutter_test/flutter_test.dart';
import 'package:profhere/core/utils/queue_utils.dart';
import 'package:profhere/domain/entities/queue_entry.dart';

void main() {
  test(
    'findNextWaitingEntry returns the waiting student with lowest position',
    () {
      final entries = <QueueEntry>[
        QueueEntry(
          id: '2',
          facultyId: 'f1',
          studentId: 's2',
          position: 2,
          status: QueueEntryStatus.waiting,
          createdAt: DateTime(2026, 3, 24),
        ),
        QueueEntry(
          id: '1',
          facultyId: 'f1',
          studentId: 's1',
          position: 1,
          status: QueueEntryStatus.waiting,
          createdAt: DateTime(2026, 3, 24),
        ),
        QueueEntry(
          id: '3',
          facultyId: 'f1',
          studentId: 's3',
          position: 3,
          status: QueueEntryStatus.called,
          createdAt: DateTime(2026, 3, 24),
        ),
      ];

      final nextEntry = QueueUtils.findNextWaitingEntry(entries);

      expect(nextEntry?.id, '1');
    },
  );

  test('waitingCount only counts waiting entries', () {
    final entries = <QueueEntry>[
      QueueEntry(
        id: '1',
        facultyId: 'f1',
        studentId: 's1',
        position: 1,
        status: QueueEntryStatus.waiting,
        createdAt: DateTime(2026, 3, 24),
      ),
      QueueEntry(
        id: '2',
        facultyId: 'f1',
        studentId: 's2',
        position: 2,
        status: QueueEntryStatus.completed,
        createdAt: DateTime(2026, 3, 24),
      ),
    ];

    expect(QueueUtils.waitingCount(entries), 1);
  });
}
