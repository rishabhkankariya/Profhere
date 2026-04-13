import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/faculty.dart';

/// Seeds initial Firestore data on first run.
/// Checks if faculty collection is empty before writing.
class MockDataSeeder {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedIfEmpty() async {
    try {
      final snap = await _db.collection('faculty').limit(1).get();
      if (snap.docs.isNotEmpty) return; // already seeded
      await _seedFaculty();
    } catch (_) {
      // Offline or no permission — skip seeding
    }
  }

  static Future<void> _seedFaculty() async {
    final batch = _db.batch();
    final now = Timestamp.now();

    final faculty = [
      {
        'id': 'faculty-001',
        'name': 'Dr. Sarah Mitchell',
        'email': 'sarah.mitchell@profhere.com',
        'department': 'Computer Science',
        'building': 'Engineering Block A',
        'cabinId': 'A-301',
        'statusIndex': FacultyStatus.available.index,
        'zone': '3rd Floor',
        'specialization': 'Machine Learning & AI',
        'lastUpdated': now,
      },
      {
        'id': 'faculty-002',
        'name': 'Prof. James Rodriguez',
        'email': 'james.rodriguez@profhere.com',
        'department': 'Computer Science',
        'building': 'Engineering Block B',
        'cabinId': 'B-205',
        'statusIndex': FacultyStatus.inLecture.index,
        'zone': '2nd Floor',
        'specialization': 'Database Systems',
        'activeContext': 'CS301 - Database Management',
        'lastUpdated': now,
      },
      {
        'id': 'faculty-003',
        'name': 'Dr. Priya Sharma',
        'email': 'priya.sharma@profhere.com',
        'department': 'Mathematics',
        'building': 'Science Block C',
        'cabinId': 'C-102',
        'statusIndex': FacultyStatus.busy.index,
        'zone': '1st Floor',
        'specialization': 'Applied Mathematics',
        'lastUpdated': now,
      },
      {
        'id': 'faculty-004',
        'name': 'Prof. Michael Chen',
        'email': 'michael.chen@profhere.com',
        'department': 'Computer Science',
        'building': 'Engineering Block A',
        'cabinId': 'A-405',
        'statusIndex': FacultyStatus.available.index,
        'zone': '4th Floor',
        'specialization': 'Software Engineering',
        'lastUpdated': now,
      },
      {
        'id': 'faculty-005',
        'name': 'Dr. Emma Wilson',
        'email': 'emma.wilson@profhere.com',
        'department': 'Physics',
        'building': 'Science Block D',
        'cabinId': 'D-201',
        'statusIndex': FacultyStatus.meeting.index,
        'zone': '2nd Floor',
        'specialization': 'Quantum Computing',
        'lastUpdated': now,
      },
      {
        'id': 'faculty-006',
        'name': 'Prof. David Kim',
        'email': 'david.kim@profhere.com',
        'department': 'Computer Science',
        'building': 'Engineering Block B',
        'cabinId': 'B-308',
        'statusIndex': FacultyStatus.away.index,
        'zone': '3rd Floor',
        'specialization': 'Computer Networks',
        'lastUpdated': now,
      },
    ];

    for (final f in faculty) {
      final id = f['id'] as String;
      final data = Map<String, dynamic>.from(f)..remove('id');
      batch.set(_db.collection('faculty').doc(id), data);
    }

    await batch.commit();
  }
}
