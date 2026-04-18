import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/repositories/faculty_repository.dart';

class FirestoreFacultyRepository implements FacultyRepository {
  static const _uuid = Uuid();
  final _col = FirebaseFirestore.instance.collection('faculty');

  Faculty _fromDoc(DocumentSnapshot doc) {
    final d = Map<String, dynamic>.from(doc.data() as Map? ?? {});
    final rawIndex = (d['statusIndex'] as num?)?.toInt() ?? 0;
    final statusIndex = rawIndex.clamp(0, FacultyStatus.values.length - 1);
    return Faculty(
      id: doc.id,
      name: d['name']?.toString() ?? 'Unknown',
      email: (d['email']?.toString() ?? '').toLowerCase(),
      department: d['department']?.toString() ?? '',
      building: d['building']?.toString() ?? '',
      cabinId: d['cabinId']?.toString() ?? '',
      status: FacultyStatus.values[statusIndex],
      zone: d['zone']?.toString(),
      specialization: d['specialization']?.toString(),
      bio: d['bio']?.toString(),
      avatarUrl: d['avatarUrl']?.toString(),
      phoneNumber: d['phoneNumber']?.toString(),
      publicationsCount: (d['publicationsCount'] as num?)?.toInt() ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      consultationCount: (d['consultationCount'] as num?)?.toInt() ?? 0,
      lastUpdated: (d['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedReturnAt: (d['expectedReturnAt'] as Timestamp?)?.toDate(),
      manualOverrideUntil: (d['manualOverrideUntil'] as Timestamp?)?.toDate(),
      activeContext: d['activeContext']?.toString(),
      customStatusText: d['customStatusText']?.toString(),
    );
  }

  Map<String, dynamic> _toMap(Faculty f) => {
    'name': f.name,
    'email': f.email.toLowerCase(),
    'department': f.department,
    'building': f.building,
    'cabinId': f.cabinId,
    'statusIndex': f.status.index,
    'zone': f.zone,
    'specialization': f.specialization,
    'bio': f.bio,
    'avatarUrl': f.avatarUrl,
    'phoneNumber': f.phoneNumber,
    'publicationsCount': f.publicationsCount,
    'rating': f.rating,
    'consultationCount': f.consultationCount,
    'lastUpdated': FieldValue.serverTimestamp(),
    'expectedReturnAt': f.expectedReturnAt != null ? Timestamp.fromDate(f.expectedReturnAt!) : null,
    'manualOverrideUntil': f.manualOverrideUntil != null ? Timestamp.fromDate(f.manualOverrideUntil!) : null,
    'activeContext': f.activeContext,
    'customStatusText': f.customStatusText,
  };

  @override
  Stream<List<Faculty>> getFaculties() {
    return _col.snapshots().map((s) => s.docs.map(_fromDoc).toList());
  }

  Stream<Faculty?> getFacultyStream(String id) {
    return _col.doc(id).snapshots().map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  @override
  Future<List<Faculty>> getFacultiesOnce() async {
    final snap = await _col.get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<Faculty?> getFacultyById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<void> updateFacultyStatus(
    String id,
    FacultyStatus status, {
    String? activeContext,
    DateTime? expectedReturnAt,
    DateTime? manualOverrideUntil,
    String? customStatusText,
  }) async {
    final data = <String, dynamic>{
      'statusIndex': status.index,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    if (activeContext != null)       data['activeContext']       = activeContext;
    if (expectedReturnAt != null)    data['expectedReturnAt']    = Timestamp.fromDate(expectedReturnAt);
    if (manualOverrideUntil != null) data['manualOverrideUntil'] = Timestamp.fromDate(manualOverrideUntil);
    if (customStatusText != null)    data['customStatusText']    = customStatusText;
    // Clear custom text when switching away from custom
    if (status != FacultyStatus.custom) data['customStatusText'] = null;

    await _col.doc(id).update(data);
  }

  @override
  Future<void> addFaculty(Faculty faculty) async {
    final id = faculty.id.isEmpty ? _uuid.v4() : faculty.id;
    await _col.doc(id).set(_toMap(faculty.copyWith(id: id)));
  }

  @override
  Future<void> updateFaculty(Faculty faculty) async {
    await _col.doc(faculty.id).set(_toMap(faculty), SetOptions(merge: true));
  }

  @override
  Future<void> deleteFaculty(String id) async {
    await _col.doc(id).delete();
  }
}
