import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/consultation.dart';
import '../datasources/local/hive_service.dart';

class HiveConsultationRepository {
  static const _uuid = Uuid();
  final _controller = StreamController<List<Consultation>>.broadcast();

  void _notify() {
    _controller.add(_getAll());
  }

  List<Consultation> _getAll() {
    return HiveService.consultations.values
        .whereType<Map>()
        .map(_fromMap)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  Consultation _fromMap(Map map) {
    return Consultation(
      id: map['id'] as String,
      facultyId: map['facultyId'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      purpose: map['purpose'] as String,
      notes: map['notes'] as String?,
      status: ConsultationStatus.values[map['statusIndex'] as int],
      requestedAt: DateTime.parse(map['requestedAt'] as String),
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      position: map['position'] as int,
      waitTimeMinutes: map['waitTimeMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> _toMap(Consultation c) {
    return {
      'id': c.id,
      'facultyId': c.facultyId,
      'studentId': c.studentId,
      'studentName': c.studentName,
      'purpose': c.purpose,
      'notes': c.notes,
      'statusIndex': c.status.index,
      'requestedAt': c.requestedAt.toIso8601String(),
      'startedAt': c.startedAt?.toIso8601String(),
      'completedAt': c.completedAt?.toIso8601String(),
      'position': c.position,
      'waitTimeMinutes': c.waitTimeMinutes,
    };
  }

  Stream<List<Consultation>> watchByFaculty(String facultyId) async* {
    yield _getAll().where((c) => c.facultyId == facultyId).toList();
    yield* _controller.stream
        .map((list) => list.where((c) => c.facultyId == facultyId).toList());
  }

  Future<List<Consultation>> getByFaculty(String facultyId) async {
    return _getAll().where((c) => c.facultyId == facultyId).toList();
  }

  Future<bool> hasActiveRequest(String studentId, String facultyId) async {
    return _getAll().any((c) =>
        c.studentId == studentId &&
        c.facultyId == facultyId &&
        (c.status == ConsultationStatus.pending ||
            c.status == ConsultationStatus.inProgress));
  }

  Future<Consultation> joinQueue({
    required String facultyId,
    required String studentId,
    required String studentName,
    required String purpose,
  }) async {
    final existing = _getAll()
        .where((c) =>
            c.facultyId == facultyId &&
            (c.status == ConsultationStatus.pending ||
                c.status == ConsultationStatus.inProgress))
        .toList();

    final position = existing.length + 1;
    final consultation = Consultation(
      id: _uuid.v4(),
      facultyId: facultyId,
      studentId: studentId,
      studentName: studentName,
      purpose: purpose,
      status: ConsultationStatus.pending,
      requestedAt: DateTime.now(),
      position: position,
      waitTimeMinutes: position * 10,
    );

    await HiveService.consultations.put(consultation.id, _toMap(consultation));
    _notify();
    return consultation;
  }

  Future<void> updateStatus(String id, ConsultationStatus status) async {
    final map = HiveService.consultations.get(id);
    if (map == null) return;
    final updated = Map<String, dynamic>.from(map as Map);
    updated['statusIndex'] = status.index;
    if (status == ConsultationStatus.inProgress) {
      updated['startedAt'] = DateTime.now().toIso8601String();
    } else if (status == ConsultationStatus.completed ||
        status == ConsultationStatus.cancelled) {
      updated['completedAt'] = DateTime.now().toIso8601String();
    }
    await HiveService.consultations.put(id, updated);
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
