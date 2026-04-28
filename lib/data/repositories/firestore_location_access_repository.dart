import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/location_access.dart';
import '../../domain/repositories/location_access_repository.dart';

class FirestoreLocationAccessRepository implements LocationAccessRepository {
  static const _uuid = Uuid();
  final _col = FirebaseFirestore.instance.collection('location_access');

  LocationAccess _fromDoc(DocumentSnapshot doc) {
    final d = Map<String, dynamic>.from(doc.data() as Map? ?? {});
    final statusIndex = (d['statusIndex'] as num?)?.toInt() ?? 0;
    final status = LocationAccessStatus.values[
        statusIndex.clamp(0, LocationAccessStatus.values.length - 1)];
    return LocationAccess(
      id: doc.id,
      facultyId: d['facultyId']?.toString() ?? '',
      studentId: d['studentId']?.toString() ?? '',
      studentName: d['studentName']?.toString() ?? '',
      studentEmail: d['studentEmail']?.toString() ?? '',
      status: status,
      nodeMcuIpAddress: d['nodeMcuIpAddress']?.toString(),
      requestedAt: (d['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (d['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (d['rejectedAt'] as Timestamp?)?.toDate(),
      revokedAt: (d['revokedAt'] as Timestamp?)?.toDate(),
      reason: d['reason']?.toString(),
    );
  }

  Map<String, dynamic> _toMap(LocationAccess access) => {
        'facultyId': access.facultyId,
        'studentId': access.studentId,
        'studentName': access.studentName,
        'studentEmail': access.studentEmail,
        'statusIndex': access.status.index,
        'nodeMcuIpAddress': access.nodeMcuIpAddress,
        'requestedAt': Timestamp.fromDate(access.requestedAt),
        'approvedAt':
            access.approvedAt != null ? Timestamp.fromDate(access.approvedAt!) : null,
        'rejectedAt':
            access.rejectedAt != null ? Timestamp.fromDate(access.rejectedAt!) : null,
        'revokedAt':
            access.revokedAt != null ? Timestamp.fromDate(access.revokedAt!) : null,
        'reason': access.reason,
      };

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Single-field query by facultyId — no composite index needed.
  Stream<List<LocationAccess>> _streamByFaculty(String facultyId) {
    return _col
        .where('facultyId', isEqualTo: facultyId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(_fromDoc).toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  /// Single-field query by studentId — no composite index needed.
  Stream<List<LocationAccess>> _streamByStudent(String studentId) {
    return _col
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(_fromDoc).toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  // ── interface implementation ──────────────────────────────────────────────

  @override
  Future<void> requestLocationAccess({
    required String facultyId,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    // Single-field query — no index needed. Filter in Dart.
    final snap = await _col.where('studentId', isEqualTo: studentId).get();
    final hasActive = snap.docs.any((doc) {
      final d = doc.data();
      if (d['facultyId'] != facultyId) return false;
      final idx = (d['statusIndex'] as num?)?.toInt() ?? 0;
      return idx == LocationAccessStatus.pending.index ||
          idx == LocationAccessStatus.approved.index;
    });
    if (hasActive) {
      throw Exception('You already have a pending or approved access request');
    }

    final access = LocationAccess(
      id: _uuid.v4(),
      facultyId: facultyId,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      status: LocationAccessStatus.pending,
      requestedAt: DateTime.now(),
    );
    await _col.doc(access.id).set(_toMap(access));
  }

  @override
  Stream<List<LocationAccess>> getAccessRequestsForFaculty(String facultyId) =>
      _streamByFaculty(facultyId);

  @override
  Stream<List<LocationAccess>> getAccessRequestsFromStudent(String studentId) =>
      _streamByStudent(studentId);

  @override
  Future<void> approveLocationAccess({
    required String accessId,
    required String nodeMcuIpAddress,
  }) async {
    await _col.doc(accessId).update({
      'statusIndex': LocationAccessStatus.approved.index,
      'nodeMcuIpAddress': nodeMcuIpAddress,
      'approvedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> rejectLocationAccess({
    required String accessId,
    required String reason,
  }) async {
    await _col.doc(accessId).update({
      'statusIndex': LocationAccessStatus.rejected.index,
      'rejectedAt': Timestamp.now(),
      'reason': reason,
    });
  }

  @override
  Future<void> revokeLocationAccess({
    required String accessId,
    required String reason,
  }) async {
    await _col.doc(accessId).update({
      'statusIndex': LocationAccessStatus.revoked.index,
      'revokedAt': Timestamp.now(),
      'reason': reason,
    });
  }

  @override
  Future<LocationAccess?> getLocationAccessById(String accessId) async {
    final doc = await _col.doc(accessId).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<bool> hasApprovedAccess({
    required String facultyId,
    required String studentId,
  }) async {
    // Single-field query, filter in Dart — no index needed.
    final snap = await _col.where('studentId', isEqualTo: studentId).get();
    return snap.docs.any((doc) {
      final d = doc.data();
      return d['facultyId'] == facultyId &&
          (d['statusIndex'] as num?)?.toInt() == LocationAccessStatus.approved.index;
    });
  }

  @override
  Future<LocationAccess?> getApprovedAccess({
    required String facultyId,
    required String studentId,
  }) async {
    // Single-field query, filter in Dart — no index needed.
    final snap = await _col.where('studentId', isEqualTo: studentId).get();
    final docs = snap.docs.where((doc) {
      final d = doc.data();
      return d['facultyId'] == facultyId &&
          (d['statusIndex'] as num?)?.toInt() == LocationAccessStatus.approved.index;
    });
    return docs.isEmpty ? null : _fromDoc(docs.first);
  }

  @override
  Stream<List<LocationAccess>> getApprovedAccessesForFaculty(String facultyId) {
    // Single-field query, filter approved in Dart — no index needed.
    return _streamByFaculty(facultyId).map(
      (list) => list.where((a) => a.isApproved).toList(),
    );
  }

  @override
  Stream<List<LocationAccess>> getAllPendingAccesses() {
    // Fetch all — filter pending in Dart. No index needed.
    return _col.snapshots().map((s) {
      final list = s.docs
          .map(_fromDoc)
          .where((a) => a.isPending)
          .toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  @override
  Stream<List<LocationAccess>> getAllAccessesForFaculty(String facultyId) =>
      _streamByFaculty(facultyId);
}
