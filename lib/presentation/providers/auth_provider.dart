import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_auth_repository.dart';
import '../../domain/entities/user.dart';

final authRepositoryProvider = Provider<FirestoreAuthRepository>((ref) {
  return FirestoreAuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;
  final bool emailVerificationSent;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.emailVerificationSent = false,
  });

  AuthState copyWith({
    bool? isLoading, String? error, User? user, bool? emailVerificationSent,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      emailVerificationSent: emailVerificationSent ?? this.emailVerificationSent,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirestoreAuthRepository _repository;
  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.login(email, password);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  Future<void> register(
    String name, String email, String password, {
    String? studentCode,
    String? phoneNumber,
    int? yearOfStudy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register(name, email, password,
          studentCode: studentCode,
          phoneNumber: phoneNumber,
          yearOfStudy: yearOfStudy);
      // register returns null — user must verify email
      state = state.copyWith(isLoading: false, emailVerificationSent: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signInWithGoogle();
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordReset(email);
  }

  Future<void> resendVerification(String email, String password) async {
    await _repository.resendVerificationEmail(email, password);
  }

  // ── Phone OTP ─────────────────────────────────────────────────────────────
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onFailed,
  }) async {
    await _repository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onFailed: onFailed,
      onAutoVerified: (credential) async {
        // Auto-verified — sign in directly
        state = state.copyWith(isLoading: true);
        try {
          final user = await _repository.signInWithPhoneOtp(
            verificationId: '',
            smsCode: '',
            credential: credential,
          );
          state = state.copyWith(isLoading: false, user: user);
        } catch (e) {
          state = state.copyWith(isLoading: false, error: _clean(e));
        }
      },
    );
  }

  Future<void> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signInWithPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  // ── Profile update ────────────────────────────────────────────────────────
  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    int? yearOfStudy,
    String? department,
    String? studentCode,
  }) async {
    final uid = state.user?.id;
    if (uid == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateProfile(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        yearOfStudy: yearOfStudy,
        department: department,
        studentCode: studentCode,
      );
      state = state.copyWith(isLoading: false, user: updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  void hydrateFromRepository(User? user) {
    state = AuthState(isLoading: false, user: user, error: state.error);
  }

  void clearError() => state = state.copyWith(error: null);

  String _clean(Object e) => e.toString()
      .replaceAll('Exception: ', '')
      .replaceAll('[firebase_auth/', '')
      .replaceAll(']', '');
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
