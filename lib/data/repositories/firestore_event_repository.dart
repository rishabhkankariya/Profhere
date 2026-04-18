import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/event.dart';

class FirestoreEventRepository {
  static const _uuid = Uuid();
  final _col = FirebaseFirestore.instance.collection('events');

  static const int _maxImageBase64Bytes = 700 * 1024;

  CollegeEvent? _fromDoc(DocumentSnapshot doc) {
    try {
      // doc.data() can be null for pending local writes on web
      final data = doc.data();
      if (data == null) return null;
      final d = data as Map<String, dynamic>;

      // createdAt is null during the local optimistic write (FieldValue.serverTimestamp)
      // Use DateTime.now() as fallback so sorting doesn't crash
      DateTime createdAt;
      final rawCreatedAt = d['createdAt'];
      if (rawCreatedAt is Timestamp) {
        createdAt = rawCreatedAt.toDate();
      } else {
        createdAt = DateTime.now();
      }

      return CollegeEvent(
        id:          doc.id,
        authorId:    d['authorId']   as String? ?? '',
        authorName:  d['authorName'] as String? ?? '',
        authorRole:  d['authorRole'] as String? ?? 'student_cr',
        title:       d['title']       as String? ?? '',
        description: d['description'] as String? ?? '',
        category: EventCategory.values[
          ((d['category'] as int?) ?? 0).clamp(0, EventCategory.values.length - 1)],
        eventDate:  (d['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        imageUrl:    d['imageUrl']   as String?,
        createdAt:   createdAt,
        isApproved:  d['isApproved'] as bool? ?? true,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[EventRepo] _fromDoc error for ${doc.id}: $e');
      return null;
    }
  }

  Stream<List<CollegeEvent>> watchAll({bool approvedOnly = true}) {
    return _col
        .snapshots()
        .handleError((e, st) {
          // Log but DO NOT rethrow — let the stream recover on next snapshot
          // ignore: avoid_print
          print('[EventRepo] watchAll error: $e');
        })
        .map((snap) {
          final list = snap.docs
              .map(_fromDoc)
              .whereType<CollegeEvent>()
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<CollegeEvent>> watchPending() => const Stream.empty();

  Future<void> add(CollegeEvent event, {bool autoApprove = false}) async {
    final id = event.id.isEmpty ? _uuid.v4() : event.id;

    String? safeImage = event.imageUrl;
    if (safeImage != null && safeImage.length > _maxImageBase64Bytes) {
      safeImage = null;
    }

    await _col.doc(id).set({
      'authorId':    event.authorId,
      'authorName':  event.authorName,
      'authorRole':  event.authorRole,
      'title':       event.title,
      'description': event.description,
      'category':    event.category.index,
      'eventDate':   Timestamp.fromDate(event.eventDate),
      'imageUrl':    safeImage,
      'createdAt':   FieldValue.serverTimestamp(),
      'isApproved':  true,
    });
  }

  Future<void> approve(String id) async {
    await _col.doc(id).update({'isApproved': true});
  }

  Future<void> update(CollegeEvent event) async {
    String? safeImage = event.imageUrl;
    if (safeImage != null && safeImage.length > _maxImageBase64Bytes) {
      safeImage = null;
    }
    await _col.doc(event.id).update({
      'title':       event.title,
      'description': event.description,
      'category':    event.category.index,
      'eventDate':   Timestamp.fromDate(event.eventDate),
      'imageUrl':    safeImage,
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
