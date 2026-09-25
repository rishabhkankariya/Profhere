enum QueueEntryStatus {
  waiting('waiting'),
  called('called'),
  completed('completed');

  const QueueEntryStatus(this.value);

  final String value;

  static QueueEntryStatus fromValue(String value) {
    return QueueEntryStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => QueueEntryStatus.waiting,
    );
  }
}

class QueueEntry {
  const QueueEntry({
    required this.id,
    required this.facultyId,
    required this.studentId,
    this.studentName,
    required this.position,
    required this.status,
    this.calledAt,
    required this.createdAt,
  });

  final String id;
  final String facultyId;
  final String studentId;
  final String? studentName;
  final int position;
  final QueueEntryStatus status;
  final DateTime? calledAt;
  final DateTime createdAt;

  QueueEntry copyWith({
    String? id,
    String? facultyId,
    String? studentId,
    String? studentName,
    int? position,
    QueueEntryStatus? status,
    DateTime? calledAt,
    DateTime? createdAt,
  }) {
    return QueueEntry(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      position: position ?? this.position,
      status: status ?? this.status,
      calledAt: calledAt ?? this.calledAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
