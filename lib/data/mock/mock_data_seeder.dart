import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/faculty.dart';
import '../../domain/entities/user.dart';

/// Seeds initial Firestore data on first run.
class MockDataSeeder {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = fb.FirebaseAuth.instance;

  static Future<void> seedIfEmpty() async {
    try {
      final snap = await _db.collection('faculty').limit(1).get();
      if (snap.docs.isNotEmpty) return; // already seeded
      await _seedFaculty();
      await _seedDemoUsers();
    } catch (e) {
      // Offline or rules blocking — skip silently
    }
  }

  // ── Faculty ───────────────────────────────────────────────────────────────
  static Future<void> _seedFaculty() async {
    final batch = _db.batch();
    final now   = Timestamp.now();

    final list = [
      _faculty('faculty-001', 'Dr. Sarah Mitchell',   'sarah.mitchell@profhere.com',   'Computer Science', 'Engineering Block A', 'A-301', FacultyStatus.available,  '3rd Floor', 'Machine Learning & AI',  now),
      _faculty('faculty-002', 'Prof. James Rodriguez', 'james.rodriguez@profhere.com',  'Computer Science', 'Engineering Block B', 'B-205', FacultyStatus.inLecture, '2nd Floor', 'Database Systems',        now, activeContext: 'CS301 - Database Management'),
      _faculty('faculty-003', 'Dr. Priya Sharma',      'priya.sharma@profhere.com',     'Mathematics',      'Science Block C',     'C-102', FacultyStatus.busy,       '1st Floor', 'Applied Mathematics',     now),
      _faculty('faculty-004', 'Prof. Michael Chen',    'michael.chen@profhere.com',     'Computer Science', 'Engineering Block A', 'A-405', FacultyStatus.available,  '4th Floor', 'Software Engineering',    now),
      _faculty('faculty-005', 'Dr. Emma Wilson',       'emma.wilson@profhere.com',      'Physics',          'Science Block D',     'D-201', FacultyStatus.meeting,    '2nd Floor', 'Quantum Computing',       now),
      _faculty('faculty-006', 'Prof. David Kim',       'david.kim@profhere.com',        'Computer Science', 'Engineering Block B', 'B-308', FacultyStatus.away,       '3rd Floor', 'Computer Networks',       now),
    ];

    for (final f in list) {
      final id = f['id'] as String;
      final data = Map<String, dynamic>.from(f)..remove('id');
      batch.set(_db.collection('faculty').doc(id), data);
    }
    await batch.commit();
  }

  static Map<String, dynamic> _faculty(
    String id, String name, String email,
    String dept, String building, String cabin,
    FacultyStatus status, String zone, String spec,
    Timestamp now, {String? activeContext}
  ) => {
    'id': id, 'name': name, 'email': email,
    'department': dept, 'building': building, 'cabinId': cabin,
    'statusIndex': status.index, 'zone': zone, 'specialization': spec,
    'lastUpdated': now, 'activeContext': activeContext,
    'publicationsCount': 0, 'rating': 0.0, 'consultationCount': 0,
  };

  // ── Demo user Firestore profiles ──────────────────────────────────────────
  // Creates Firestore user docs for demo accounts.
  // Firebase Auth accounts must be created manually in the console.
  static Future<void> _seedDemoUsers() async {
    final now = Timestamp.now();

    // Map of email → {uid from Firebase Auth, profile data}
    // We look up UIDs by signing in temporarily
    final demos = [
      {'email': 'admin@profhere.com',                        'password': 'admin123',    'name': 'Admin User',       'roleIndex': UserRole.admin.index},
      {'email': 'sarah.mitchell@profhere.com',               'password': 'faculty123',  'name': 'Dr. Sarah Mitchell','roleIndex': UserRole.faculty.index, 'dept': 'Computer Science'},
      {'email': 'alex.thompson@student.profhere.com',        'password': 'student123',  'name': 'Alex Thompson',    'roleIndex': UserRole.student.index, 'code': 'STU2024001'},
    ];

    for (final demo in demos) {
      try {
        // Sign in to get UID
        final cred = await _auth.signInWithEmailAndPassword(
          email: demo['email'] as String,
          password: demo['password'] as String,
        );
        final uid = cred.user!.uid;

        // Only write if doc doesn't exist
        final doc = await _db.collection('users').doc(uid).get();
        if (!doc.exists) {
          await _db.collection('users').doc(uid).set({
            'name': demo['name'],
            'roleIndex': demo['roleIndex'],
            'studentCode': demo['code'],
            'department': demo['dept'],
            'avatarUrl': null,
            'phoneNumber': null,
            'yearOfStudy': null,
            'createdAt': now,
            'lastLoginAt': now,
          });
        }
        await _auth.signOut();
      } catch (_) {
        // Account doesn't exist in Firebase Auth yet — skip
        await _auth.signOut().catchError((_) {});
      }
    }
  }
}
