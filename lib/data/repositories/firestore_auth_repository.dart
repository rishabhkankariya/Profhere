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
      mustChangePassword: d['mustChangePassword'] as bool? ?? false,
      isCR: d['isCR'] as bool? ?? false,
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

  // ── Email/Password login — no email verification required ────────────────
  @override
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    final fbUser = cred.user!;
    final doc = await _users.doc(fbUser.uid).get();
    if (!doc.exists) throw Exception('Account not found. Please contact admin.');
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
    await fbUser.updateDisplayName(name);

    // Try to match with college database by email
    String? matchedCode, matchedDept, matchedPhone;
    int? matchedYear;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('college_students')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        matchedCode  = d['studentCode'] as String?;
        matchedDept  = d['department'] as String?;
        matchedPhone = d['phoneNumber'] as String?;
        matchedYear  = (d['yearOfStudy'] as num?)?.toInt();
      }
    } catch (_) {}

    await _users.doc(fbUser.uid).set({
      'name': name,
      'roleIndex': UserRole.student.index,
      'studentCode': studentCode ?? matchedCode,
      'department': matchedDept,
      'avatarUrl': null,
      'phoneNumber': phoneNumber ?? matchedPhone,
      'yearOfStudy': yearOfStudy ?? matchedYear,
      'mustChangePassword': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    final doc = await _users.doc(fbUser.uid).get();
    return _fromDoc(doc, fbUser);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<User?> signInWithGoogle() async {
    late fb.UserCredential cred;

    try {
      // Use Firebase's built-in Google provider — works on web via popup,
      // and on mobile via redirect/native flow.
      final provider = fb.GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      cred = await _auth.signInWithPopup(provider);
    } on fb.FirebaseAuthException catch (e) {
      // popup-closed-by-user or cancelled — not an error
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') return null;
      // On mobile signInWithPopup isn't supported — fall back to google_sign_in
      final googleUser = await _google.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      cred = await _auth.signInWithCredential(credential);
    } catch (_) {
      // Any other error — try mobile fallback
      final googleUser = await _google.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      cred = await _auth.signInWithCredential(credential);
    }

    final fbUser = cred.user!;

    // Create Firestore profile if first time
    final doc = await _users.doc(fbUser.uid).get();
    if (!doc.exists) {
      await _users.doc(fbUser.uid).set({
        'name': fbUser.displayName ?? 'User',
        'roleIndex': UserRole.student.index,
        'studentCode': null,
        'department': null,
        'avatarUrl': fbUser.photoURL,
        'phoneNumber': fbUser.phoneNumber,
        'yearOfStudy': null,
        'isCR': false,
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
  /// Creates a Firebase Auth account for a faculty member with an auto-generated
  /// demo password (FirstName + 4-digit random), saves it to Firestore, and
  /// sends a password-reset email so the faculty can set their own password.
  /// Returns the generated demo password so admin can share it if needed.
  Future<String> createFacultyAccountWithDemoPassword({
    required String email,
    required String name,
    required String facultyFirestoreId,
  }) async {
    // Generate demo password: first word of name + 4 random digits
    final firstName = name.split(' ').first;
    final digits = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    final demoPassword = '$firstName@$digits';

    // Create Firebase Auth account
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: demoPassword);
    final uid = cred.user!.uid;

    // Copy Firestore data from faculty doc to users collection
    final facultyDoc = await FirebaseFirestore.instance
        .collection('faculty').doc(facultyFirestoreId).get();
    final d = facultyDoc.data() ?? {};

    await _users.doc(uid).set({
      'name': d['name'] ?? name,
      'roleIndex': UserRole.faculty.index,
      'studentCode': null,
      'department': d['department'],
      'avatarUrl': d['avatarUrl'],
      'phoneNumber': null,
      'yearOfStudy': null,
      'mustChangePassword': true, // flag to force password change on first login
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    // Send password reset email so faculty can set their own password
    await _auth.sendPasswordResetEmail(email: email.trim());

    // Sign out the newly created account so admin stays logged in
    await _auth.signOut();

    return demoPassword;
  }

  /// Sends a password reset email to a faculty member.
  Future<void> sendFacultyPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Legacy manual password set — kept for admin who wants to set a specific password.
  Future<void> createFacultyAccount({
    required String email,
    required String password,
    required String facultyFirestoreId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final uid = cred.user!.uid;
    final facultyDoc = await FirebaseFirestore.instance
        .collection('faculty').doc(facultyFirestoreId).get();
    final d = facultyDoc.data() ?? {};
    await _users.doc(uid).set({
      'name': d['name'] ?? email,
      'roleIndex': UserRole.faculty.index,
      'studentCode': null,
      'department': d['department'],
      'avatarUrl': d['avatarUrl'],
      'phoneNumber': null,
      'yearOfStudy': null,
      'mustChangePassword': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
    await _auth.signOut();
  }

  /// Changes the current user's own password.
  Future<void> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Not signed in');
    // Re-authenticate first
    final cred = fb.EmailAuthProvider.credential(
        email: fbUser.email!, password: currentPassword);
    await fbUser.reauthenticateWithCredential(cred);
    await fbUser.updatePassword(newPassword);
  }

  Future<User?> updateProfile({    required String uid,
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
    await _google.signOut().catchError((_) => null);
    await _auth.signOut();
  }
}
