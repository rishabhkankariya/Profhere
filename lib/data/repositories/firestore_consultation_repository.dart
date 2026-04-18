import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/consultation.dart';

class FirestoreConsultationRepository {
  static const _uuid = Uuid();
  final _col = FirebaseFirestore.instance.collection('consultations');

  Consultation _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Consultation(
      id: doc.id,
      facultyId: d['facultyId'] as String? ?? '',
      studentId: d['studentId'] as String? ?? '',
      studentName: d['studentName'] as String? ?? '',
      purpose: d['purpose'] as String? ?? '',
      notes: d['notes'] as String?,
      status: ConsultationStatus.values[d['statusIndex'] as int? ?? 0],
      requestedAt: (d['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      position: d['position'] as int? ?? 1,
      waitTimeMinutes: d['waitTimeMinutes'] as int? ?? 0,
    );
  }

  Stream<List<Consultation>> watchByFaculty(String facultyId) {
    // No orderBy to avoid composite index requirement — sort in Dart
    return _col
        .where('facultyId', isEqualTo: facultyId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(_fromDoc).toList();
          list.sort((a, b) => a.position.compareTo(b.position));
          return list;
        });
  }

  /// Stream all active (pending/inProgress) consultations for a student.
  Stream<List<Consultation>> watchByStudent(String studentId) {
    return _col
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .handleError((_) {})
        .map((s) => s.docs
            .map(_fromDoc)
            .where((c) =>
                c.status == ConsultationStatus.pending ||
                c.status == ConsultationStatus.inProgress)
            .toList());
  }

  Future<List<Consultation>> getByFaculty(String facultyId) async {
    final snap = await _col
        .where('facultyId', isEqualTo: facultyId)
        .get();
    final list = snap.docs.map(_fromDoc).toList();
    list.sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  Future<bool> hasActiveRequest(String studentId, String facultyId) async {
    // Query only by studentId to avoid composite index, filter in Dart
    final snap = await _col
        .where('studentId', isEqualTo: studentId)
        .where('facultyId', isEqualTo: facultyId)
        .get();
    return snap.docs.any((doc) {
      final idx = doc.data()['statusIndex'] as int? ?? 0;
      return idx == ConsultationStatus.pending.index ||
             idx == ConsultationStatus.inProgress.index;
    });
  }

  Future<Consultation> joinQueue({
    required String facultyId,
    required String studentId,
    required String studentName,
    required String purpose,
  }) async {
    // Count active queue entries for position — no whereIn to avoid index
    final existing = await _col
        .where('facultyId', isEqualTo: facultyId)
        .get();
    final activeCount = existing.docs.where((doc) {
      final idx = doc.data()['statusIndex'] as int? ?? 0;
      return idx == ConsultationStatus.pending.index ||
             idx == ConsultationStatus.inProgress.index;
    }).length;
    final position = activeCount + 1;
    final id = _uuid.v4();

    await _col.doc(id).set({
      'facultyId': facultyId,
      'studentId': studentId,
      'studentName': studentName,
      'purpose': purpose,
      'notes': null,
      'statusIndex': ConsultationStatus.pending.index,
      'requestedAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'completedAt': null,
      'position': position,
      'waitTimeMinutes': position * 10,
    });

    final doc = await _col.doc(id).get();
    return _fromDoc(doc);
  }

  Future<void> updateStatus(String id, ConsultationStatus status) async {
    final update = <String, dynamic>{'statusIndex': status.index};
    if (status == ConsultationStatus.inProgress) {
      update['startedAt'] = FieldValue.serverTimestamp();
    } else if (status == ConsultationStatus.completed ||
        status == ConsultationStatus.cancelled) {
      update['completedAt'] = FieldValue.serverTimestamp();
    }
    await _col.doc(id).update(update);
  }
}
