import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/faculty_model.dart';
import '../models/academic_model.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/activity_log.dart';
import '../datasources/local/hive_service.dart';

class MockDataGenerator {
  static const _uuid = Uuid();

  static Future<void> seedIfEmpty() async {
    if (HiveService.users.isEmpty) {
      await _seedUsers();
    }
    if (HiveService.faculty.isEmpty) {
      await _seedFaculty();
    } else {
      // Migrate existing records — strip only bio, keep specialization
      for (final key in HiveService.faculty.keys) {
        final model = HiveService.faculty.get(key);
        if (model != null && model.bio != null) {
          await HiveService.faculty.put(key, model.copyWith(bio: null));
        }
      }
    }
    if (HiveService.subjects.isEmpty) {
      await _seedAcademicData();
    }
  }

  static Future<void> _seedUsers() async {
    final users = [
      UserModel(
        id: 'admin-001',
        name: 'Admin User',
        email: 'admin@profhere.com',
        roleIndex: UserRole.admin.index,
        createdAt: DateTime.now(),
        password: 'admin123',
      ),
      UserModel(
        id: 'faculty-001',
        name: 'Dr. Sarah Mitchell',
        email: 'sarah.mitchell@profhere.com',
        roleIndex: UserRole.faculty.index,
        department: 'Computer Science',
        createdAt: DateTime.now(),
        password: 'faculty123',
      ),
      UserModel(
        id: 'student-001',
        name: 'Alex Thompson',
        email: 'alex.thompson@student.profhere.com',
        roleIndex: UserRole.student.index,
        studentCode: 'STU2024001',
        department: 'Computer Science',
        createdAt: DateTime.now(),
        password: 'student123',
      ),
      UserModel(
        id: 'student-002',
        name: 'Emily Chen',
        email: 'emily.chen@student.profhere.com',
        roleIndex: UserRole.student.index,
        studentCode: 'STU2024002',
        department: 'Computer Science',
        createdAt: DateTime.now(),
        password: 'student123',
      ),
    ];

    for (final user in users) {
      await HiveService.users.put(user.id, user);
    }
  }

  static Future<void> _seedFaculty() async {
    final facultyList = [
      FacultyModel(
        id: 'faculty-001',
        name: 'Dr. Sarah Mitchell',
        email: 'sarah.mitchell@profhere.com',
        department: 'Computer Science',
        building: 'Engineering Block A',
        cabinId: 'A-301',
        statusIndex: FacultyStatus.available.index,
        zone: '3rd Floor',
        specialization: 'Machine Learning & AI',
        lastUpdated: DateTime.now(),
      ),
      FacultyModel(
        id: 'faculty-002',
        name: 'Prof. James Rodriguez',
        email: 'james.rodriguez@profhere.com',
        department: 'Computer Science',
        building: 'Engineering Block B',
        cabinId: 'B-205',
        statusIndex: FacultyStatus.inLecture.index,
        zone: '2nd Floor',
        specialization: 'Database Systems',
        lastUpdated: DateTime.now(),
        activeContext: 'CS301 - Database Management',
      ),
      FacultyModel(
        id: 'faculty-003',
        name: 'Dr. Priya Sharma',
        email: 'priya.sharma@profhere.com',
        department: 'Mathematics',
        building: 'Science Block C',
        cabinId: 'C-102',
        statusIndex: FacultyStatus.busy.index,
        zone: '1st Floor',
        specialization: 'Applied Mathematics',
        lastUpdated: DateTime.now(),
      ),
      FacultyModel(
        id: 'faculty-004',
        name: 'Prof. Michael Chen',
        email: 'michael.chen@profhere.com',
        department: 'Computer Science',
        building: 'Engineering Block A',
        cabinId: 'A-405',
        statusIndex: FacultyStatus.available.index,
        zone: '4th Floor',
        specialization: 'Software Engineering',
        lastUpdated: DateTime.now(),
      ),
      FacultyModel(
        id: 'faculty-005',
        name: 'Dr. Emma Wilson',
        email: 'emma.wilson@profhere.com',
        department: 'Physics',
        building: 'Science Block D',
        cabinId: 'D-201',
        statusIndex: FacultyStatus.meeting.index,
        zone: '2nd Floor',
        specialization: 'Quantum Computing',
        lastUpdated: DateTime.now(),
      ),
      FacultyModel(
        id: 'faculty-006',
        name: 'Prof. David Kim',
        email: 'david.kim@profhere.com',
        department: 'Computer Science',
        building: 'Engineering Block B',
        cabinId: 'B-308',
        statusIndex: FacultyStatus.away.index,
        zone: '3rd Floor',
        specialization: 'Computer Networks',
        lastUpdated: DateTime.now(),
        expectedReturnAt: DateTime.now().add(const Duration(hours: 2)),
      ),
    ];

    for (final faculty in facultyList) {
      await HiveService.faculty.put(faculty.id, faculty);
    }
  }

  static Future<void> _seedAcademicData() async {
    final subjects = [
      SubjectModel(
        id: 'sub-001',
        code: 'CS-401',
        name: 'Machine Learning',
        facultyId: 'faculty-001',
        facultyName: 'Dr. Sarah Mitchell',
        description: 'Introduction to machine learning algorithms and applications.',
        credits: 4,
        markScheme: {'Assignment': 20, 'Midterm': 30, 'Final': 50},
      ),
      SubjectModel(
        id: 'sub-002',
        code: 'CS-301',
        name: 'Database Management',
        facultyId: 'faculty-002',
        facultyName: 'Prof. James Rodriguez',
        description: 'Relational databases, SQL, and distributed systems.',
        credits: 3,
        markScheme: {'Assignment': 20, 'Midterm': 30, 'Final': 50},
      ),
      SubjectModel(
        id: 'sub-003',
        code: 'MATH-201',
        name: 'Applied Mathematics',
        facultyId: 'faculty-003',
        facultyName: 'Dr. Priya Sharma',
        description: 'Mathematical modeling and computational methods.',
        credits: 3,
        markScheme: {'Assignment': 20, 'Midterm': 30, 'Final': 50},
      ),
      SubjectModel(
        id: 'sub-004',
        code: 'CS-201',
        name: 'Software Engineering',
        facultyId: 'faculty-004',
        facultyName: 'Prof. Michael Chen',
        description: 'Software design patterns and architecture.',
        credits: 3,
        markScheme: {'Assignment': 20, 'Midterm': 30, 'Final': 50},
      ),
    ];
    for (final s in subjects) {
      await HiveService.subjects.put(s.id, s);
    }

    final marks = [
      StudentMarkModel(
        id: 'mark-001',
        studentId: 'student-001',
        studentName: 'Alex Thompson',
        subjectId: 'sub-001',
        scores: {'Assignment': 18.0, 'Midterm': 27.0, 'Final': 44.0},
        lastUpdated: DateTime.now(),
      ),
      StudentMarkModel(
        id: 'mark-002',
        studentId: 'student-001',
        studentName: 'Alex Thompson',
        subjectId: 'sub-002',
        scores: {'Assignment': 17.0, 'Midterm': 25.0, 'Final': 42.0},
        lastUpdated: DateTime.now(),
      ),
      StudentMarkModel(
        id: 'mark-003',
        studentId: 'student-001',
        studentName: 'Alex Thompson',
        subjectId: 'sub-003',
        scores: {'Assignment': 19.0, 'Midterm': 28.0, 'Final': 46.0},
        lastUpdated: DateTime.now(),
      ),
      StudentMarkModel(
        id: 'mark-004',
        studentId: 'student-002',
        studentName: 'Emily Chen',
        subjectId: 'sub-001',
        scores: {'Assignment': 20.0, 'Midterm': 29.0, 'Final': 48.0},
        lastUpdated: DateTime.now(),
      ),
    ];
    for (final m in marks) {
      await HiveService.marks.put(m.id, m);
    }

    final timetable = [
      TimetableModel(
        id: 'tt-001',
        subjectId: 'sub-001',
        subjectName: 'Machine Learning',
        facultyId: 'faculty-001',
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '11:00',
        room: 'Hall A-201',
      ),
      TimetableModel(
        id: 'tt-002',
        subjectId: 'sub-001',
        subjectName: 'Machine Learning',
        facultyId: 'faculty-001',
        dayOfWeek: 3,
        startTime: '09:00',
        endTime: '11:00',
        room: 'Hall A-201',
      ),
      TimetableModel(
        id: 'tt-003',
        subjectId: 'sub-002',
        subjectName: 'Database Management',
        facultyId: 'faculty-002',
        dayOfWeek: 2,
        startTime: '13:00',
        endTime: '15:00',
        room: 'Lab B-105',
      ),
      TimetableModel(
        id: 'tt-004',
        subjectId: 'sub-003',
        subjectName: 'Applied Mathematics',
        facultyId: 'faculty-003',
        dayOfWeek: 4,
        startTime: '10:00',
        endTime: '12:00',
        room: 'Science Hall C-12',
      ),
      TimetableModel(
        id: 'tt-005',
        subjectId: 'sub-004',
        subjectName: 'Software Engineering',
        facultyId: 'faculty-004',
        dayOfWeek: 5,
        startTime: '14:00',
        endTime: '16:00',
        room: 'Engineering Lab A-105',
      ),
    ];
    for (final t in timetable) {
      await HiveService.timetable.put(t.id, t);
    }
  }

  static Future<void> addActivityLog({
    required ActivityType action,
    required String actorId,
    required String actorName,
    String? actorRole,
    String? targetId,
    String? targetName,
    String? statusLabel,
  }) async {
    final log = {
      'id': _uuid.v4(),
      'action': action.name,
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'targetId': targetId,
      'targetName': targetName,
      'statusLabel': statusLabel,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await HiveService.activities.add(log);
  }
}
