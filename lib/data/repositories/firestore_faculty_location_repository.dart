import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/faculty_location.dart';
import '../../domain/repositories/faculty_location_repository.dart';

class FirestoreFacultyLocationRepository implements FacultyLocationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'faculty_locations';

  @override
  Stream<FacultyLocation?> getFacultyLocation(String facultyId) {
    return _firestore
        .collection(_collection)
        .doc(facultyId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    });
  }

  @override
  Future<FacultyLocation?> getLastKnownLocation(String facultyId) async {
    final doc = await _firestore.collection(_collection).doc(facultyId).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }

  @override
  Future<void> updateFacultyLocation({
    required String facultyId,
    required String building,
    required String floor,
    String? zone,
    String? cabinId,
    required String nodeMcuIp,
    required bool isPresent,
  }) async {
    await _firestore.collection(_collection).doc(facultyId).set({
      'facultyId': facultyId,
      'building': building,
      'floor': floor,
      'zone': zone,
      'cabinId': cabinId,
      'nodeMcuIp': nodeMcuIp,
      'lastUpdated': FieldValue.serverTimestamp(),
      'isPresent': isPresent,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> markFacultyAbsent(String facultyId) async {
    await _firestore.collection(_collection).doc(facultyId).update({
      'isPresent': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  FacultyLocation _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FacultyLocation(
      facultyId: data['facultyId'] as String,
      building: data['building'] as String,
      floor: data['floor'] as String,
      zone: data['zone'] as String?,
      cabinId: data['cabinId'] as String?,
      nodeMcuIp: data['nodeMcuIp'] as String,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPresent: data['isPresent'] as bool? ?? false,
    );
  }
}
