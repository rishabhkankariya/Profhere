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
    return _col
        .where('facultyId', isEqualTo: facultyId)
        .orderBy('position')
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  Future<List<Consultation>> getByFaculty(String facultyId) async {
    final snap = await _col
        .where('facultyId', isEqualTo: facultyId)
        .orderBy('position')
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Future<bool> hasActiveRequest(String studentId, String facultyId) async {
    final snap = await _col
        .where('studentId', isEqualTo: studentId)
        .where('facultyId', isEqualTo: facultyId)
        .where('statusIndex', whereIn: [
          ConsultationStatus.pending.index,
          ConsultationStatus.inProgress.index,
        ])
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<Consultation> joinQueue({
    required String facultyId,
    required String studentId,
    required String studentName,
    required String purpose,
  }) async {
    // Count active queue entries for position
    final existing = await _col
        .where('facultyId', isEqualTo: facultyId)
        .where('statusIndex', whereIn: [
          ConsultationStatus.pending.index,
          ConsultationStatus.inProgress.index,
        ])
        .get();

    final position = existing.docs.length + 1;
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
