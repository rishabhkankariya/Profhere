import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/academic.dart';

class FirestoreTimetableRepository {
  static const _uuid = Uuid();
  final _col = FirebaseFirestore.instance.collection('timetable');

  TimetableEntry _fromDoc(DocumentSnapshot doc) {
    final d = Map<String, dynamic>.from(doc.data() as Map? ?? {});
    return TimetableEntry(
      id: doc.id,
      subjectId: d['subjectId'] as String? ?? '',
      subjectName: d['subjectName'] as String? ?? '',
      facultyId: d['facultyId'] as String? ?? '',
      dayOfWeek: d['dayOfWeek'] as int? ?? 1,
      startTime: d['startTime'] as String? ?? '09:00',
      endTime: d['endTime'] as String? ?? '10:00',
      room: d['room'] as String? ?? '',
    );
  }

  Future<List<TimetableEntry>> getByFaculty(String facultyId) async {
    final snap = await _col
        .where('facultyId', isEqualTo: facultyId)
        .get();
    final list = snap.docs.map(_fromDoc).toList();
    list.sort((a, b) {
      final dayComp = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayComp != 0) return dayComp;
      return a.startTime.compareTo(b.startTime);
    });
    return list;
  }

  Future<void> addEntry(TimetableEntry entry) async {
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    await _col.doc(id).set({
      'subjectId': entry.subjectId,
      'subjectName': entry.subjectName,
      'facultyId': entry.facultyId,
      'dayOfWeek': entry.dayOfWeek,
      'startTime': entry.startTime,
      'endTime': entry.endTime,
      'room': entry.room,
    });
  }

  Future<void> updateEntry(TimetableEntry entry) async {
    await _col.doc(entry.id).update({
      'subjectName': entry.subjectName,
      'dayOfWeek': entry.dayOfWeek,
      'startTime': entry.startTime,
      'endTime': entry.endTime,
      'room': entry.room,
    });
  }

  Future<void> deleteEntry(String id) async {
    await _col.doc(id).delete();
  }
}
