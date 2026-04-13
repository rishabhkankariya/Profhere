import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/repositories/faculty_repository.dart';

class FirestoreFacultyRepository implements FacultyRepository {
  static const _uuid = Uuid();
  final _col = FirebaseFirestore.instance.collection('faculty');

  Faculty _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Faculty(
      id: doc.id,
      name: d['name'] as String,
      email: d['email'] as String,
      department: d['department'] as String,
      building: d['building'] as String,
      cabinId: d['cabinId'] as String,
      status: FacultyStatus.values[d['statusIndex'] as int? ?? 0],
      zone: d['zone'] as String?,
      specialization: d['specialization'] as String?,
      bio: d['bio'] as String?,
      avatarUrl: d['avatarUrl'] as String?,
      phoneNumber: d['phoneNumber'] as String?,
      publicationsCount: d['publicationsCount'] as int? ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      consultationCount: d['consultationCount'] as int? ?? 0,
      lastUpdated: (d['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedReturnAt: (d['expectedReturnAt'] as Timestamp?)?.toDate(),
      manualOverrideUntil: (d['manualOverrideUntil'] as Timestamp?)?.toDate(),
      activeContext: d['activeContext'] as String?,
    );
  }

  Map<String, dynamic> _toMap(Faculty f) => {
    'name': f.name,
    'email': f.email,
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
  };

  @override
  Stream<List<Faculty>> getFaculties() {
    return _col.snapshots().map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<List<Faculty>> getFacultiesOnce() async {
    final snap = await _col.get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<Faculty?> getFacultyById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  @override
  Future<void> updateFacultyStatus(String id, FacultyStatus status, {
    String? activeContext, DateTime? expectedReturnAt, DateTime? manualOverrideUntil,
  }) async {
    await _col.doc(id).update({
      'statusIndex': status.index,
      'activeContext': activeContext,
      'expectedReturnAt': expectedReturnAt != null ? Timestamp.fromDate(expectedReturnAt) : null,
      'manualOverrideUntil': manualOverrideUntil != null ? Timestamp.fromDate(manualOverrideUntil) : null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
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
