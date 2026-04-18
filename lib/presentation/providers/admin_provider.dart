import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';

// ── Student list from Firestore ───────────────────────────────────────────────

final _usersCol = FirebaseFirestore.instance.collection('users');

final allStudentsProvider = StreamProvider<List<User>>((ref) {
  return _usersCol
      .where('roleIndex', isEqualTo: UserRole.student.index)
      .snapshots()
      .handleError((_) {})
      .map((snap) => snap.docs.map(_userFromDoc).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));
});

final allUsersProvider = StreamProvider<List<User>>((ref) {
  return _usersCol
      .snapshots()
      .handleError((_) {})
      .map((snap) => snap.docs.map(_userFromDoc).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));
});

User _userFromDoc(DocumentSnapshot doc) {
  final d = doc.data() as Map<String, dynamic>? ?? {};
  return User(
    id: doc.id,
    name: d['name'] as String? ?? 'Unknown',
    email: d['email'] as String? ?? '',
    avatarUrl: d['avatarUrl'] as String?,
    role: UserRole.values[(d['roleIndex'] as int? ?? 0)
        .clamp(0, UserRole.values.length - 1)],
    studentCode: d['studentCode'] as String?,
    department: d['department'] as String?,
    phoneNumber: d['phoneNumber'] as String?,
    yearOfStudy: d['yearOfStudy'] as int?,
    createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    lastLoginAt: (d['lastLoginAt'] as Timestamp?)?.toDate(),
    mustChangePassword: d['mustChangePassword'] as bool? ?? false,
    isCR: d['isCR'] as bool? ?? false,
  );
}

// ── Blocked students ──────────────────────────────────────────────────────────

final blockedStudentsProvider = StreamProvider<Set<String>>((ref) {
  return FirebaseFirestore.instance
      .collection('blocked_users')
      .snapshots()
      .handleError((_) {})
      .map((snap) => snap.docs.map((d) => d.id).toSet());
});

class AdminUserNotifier extends StateNotifier<AsyncValue<void>> {
  AdminUserNotifier() : super(const AsyncValue.data(null));

  Future<void> blockStudent(String uid) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('blocked_users')
          .doc(uid)
          .set({'blockedAt': FieldValue.serverTimestamp()});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unblockStudent(String uid) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('blocked_users')
          .doc(uid)
          .delete();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteStudent(String uid) async {
    state = const AsyncValue.loading();
    try {
      await _usersCol.doc(uid).delete();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStudentNotes(String uid, String notes) async {
    await _usersCol.doc(uid).update({'adminNotes': notes});
  }

  /// Toggle CR status for a student — faculty/admin only
  Future<bool> toggleCR(String uid, bool isCR) async {
    state = const AsyncValue.loading();
    try {
      await _usersCol.doc(uid).update({'isCR': isCR});
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final adminUserNotifierProvider =
    StateNotifierProvider<AdminUserNotifier, AsyncValue<void>>(
        (_) => AdminUserNotifier());

// ── All consultations stream (admin view) ─────────────────────────────────────

final allConsultationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('consultations')
      .snapshots()
      .handleError((_) {})
      .map((snap) => snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return data;
          }).toList()
        ..sort((a, b) {
          final ta = (a['requestedAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tb = (b['requestedAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return tb.compareTo(ta); // newest first
        }));
});
