import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirestoreAuthRepository implements AuthRepository {
  final _auth   = fb.FirebaseAuth.instance;
  final _users  = FirebaseFirestore.instance.collection('users');
  final _google = GoogleSignIn();

  // ── Map Firestore doc → domain User ──────────────────────────────────────
  User _fromDoc(DocumentSnapshot doc, fb.User fbUser) {
    final d = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: d['name'] as String? ?? fbUser.displayName ?? 'User',
      email: fbUser.email ?? '',
      avatarUrl: d['avatarUrl'] as String? ?? fbUser.photoURL,
      role: UserRole.values[d['roleIndex'] as int? ?? 0],
      studentCode: d['studentCode'] as String?,
      department: d['department'] as String?,
      phoneNumber: d['phoneNumber'] as String?,
      yearOfStudy: d['yearOfStudy'] as int?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (d['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  // ── Auth state stream ─────────────────────────────────────────────────────
  @override
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      final doc = await _users.doc(fbUser.uid).get();
      if (!doc.exists) return null;
      return _fromDoc(doc, fbUser);
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    final doc = await _users.doc(fbUser.uid).get();
    if (!doc.exists) return null;
    return _fromDoc(doc, fbUser);
  }

  // ── Email/Password login ──────────────────────────────────────────────────
  @override
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    final fbUser = cred.user!;

    // Get Firestore profile first to check role
    final doc = await _users.doc(fbUser.uid).get();

    // Only enforce email verification for students
    // Admin and faculty accounts are pre-created and don't need verification
    if (doc.exists) {
      final roleIndex = (doc.data() as Map<String, dynamic>)['roleIndex'] as int? ?? 0;
      final isStudent = roleIndex == UserRole.student.index;
      if (isStudent && !fbUser.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before signing in. Check your inbox for the verification link.');
      }
    } else if (!fbUser.emailVerified) {
      await _auth.signOut();
      throw Exception('Please verify your email before signing in. Check your inbox for the verification link.');
    }

    await _users.doc(fbUser.uid).update({'lastLoginAt': FieldValue.serverTimestamp()});
    final updatedDoc = await _users.doc(fbUser.uid).get();
    return _fromDoc(updatedDoc, fbUser);
  }

  // ── Email/Password register ───────────────────────────────────────────────
  @override
  Future<User?> register(
    String name,
    String email,
    String password, {
    String? studentCode,
    String? phoneNumber,
    int? yearOfStudy,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final fbUser = cred.user!;

    // Update display name
    await fbUser.updateDisplayName(name);

    // Send verification email
    await fbUser.sendEmailVerification();

    // Save profile to Firestore
    await _users.doc(fbUser.uid).set({
      'name': name,
      'roleIndex': UserRole.student.index,
      'studentCode': studentCode,
      'department': null,
      'avatarUrl': null,
      'phoneNumber': phoneNumber,
      'yearOfStudy': yearOfStudy,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    // Sign out — user must verify email first
    await _auth.signOut();

    // Return null so the UI shows "check your email" instead of navigating
    return null;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<User?> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final fbUser = cred.user!;

    // Create Firestore profile if first time
    final doc = await _users.doc(fbUser.uid).get();
    if (!doc.exists) {
      await _users.doc(fbUser.uid).set({
        'name': fbUser.displayName ?? googleUser.displayName ?? 'User',
        'roleIndex': UserRole.student.index,
        'studentCode': null,
        'department': null,
        'avatarUrl': fbUser.photoURL,
        'phoneNumber': fbUser.phoneNumber,
        'yearOfStudy': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _users.doc(fbUser.uid).update({'lastLoginAt': FieldValue.serverTimestamp()});
    }

    final updatedDoc = await _users.doc(fbUser.uid).get();
    return _fromDoc(updatedDoc, fbUser);
  }

  // ── Phone OTP — Step 1: send code ────────────────────────────────────────
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onFailed,
    required void Function(fb.PhoneAuthCredential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: (e) {
        String msg = 'Phone verification failed.';
        if (e.code == 'invalid-phone-number') msg = 'Invalid phone number format.';
        if (e.code == 'too-many-requests') msg = 'Too many requests. Try again later.';
        onFailed(msg);
      },
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ── Phone OTP — Step 2: verify code & sign in ─────────────────────────────
  Future<User?> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    fb.PhoneAuthCredential? credential,
  }) async {
    final authCredential = credential ?? fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await _auth.signInWithCredential(authCredential);
    final fbUser = cred.user!;

    final doc = await _users.doc(fbUser.uid).get();
    if (!doc.exists) {
      await _users.doc(fbUser.uid).set({
        'name': fbUser.displayName ?? 'User',
        'roleIndex': UserRole.student.index,
        'studentCode': null,
        'department': null,
        'avatarUrl': null,
        'phoneNumber': fbUser.phoneNumber,
        'yearOfStudy': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _users.doc(fbUser.uid).update({'lastLoginAt': FieldValue.serverTimestamp()});
    }

    final updatedDoc = await _users.doc(fbUser.uid).get();
    return _fromDoc(updatedDoc, fbUser);
  }

  // ── Update profile ────────────────────────────────────────────────────────
  Future<User?> updateProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    int? yearOfStudy,
    String? department,
    String? studentCode,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (yearOfStudy != null) updates['yearOfStudy'] = yearOfStudy;
    if (department != null) updates['department'] = department;
    if (studentCode != null) updates['studentCode'] = studentCode;

    if (updates.isNotEmpty) {
      await _users.doc(uid).update(updates);
      if (name != null) await _auth.currentUser?.updateDisplayName(name);
    }

    final fbUser = _auth.currentUser!;
    final doc = await _users.doc(uid).get();
    return _fromDoc(doc, fbUser);
  }
  Future<void> resendVerificationEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    await cred.user?.sendEmailVerification();
    await _auth.signOut();
  }

  // ── Password reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> logout() async {
    await _google.signOut().catchError((_) {});
    await _auth.signOut();
  }
}
