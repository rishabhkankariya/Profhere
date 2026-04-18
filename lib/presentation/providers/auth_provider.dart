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

  const AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, User? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
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
      final user = await _repository.register(name, email, password,
          studentCode: studentCode,
          phoneNumber: phoneNumber,
          yearOfStudy: yearOfStudy);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  Future<void> updateProfile({
    String? name, String? phoneNumber,
    int? yearOfStudy, String? department, String? studentCode,
  }) async {
    final uid = state.user?.id;
    if (uid == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateProfile(
        uid: uid, name: name, phoneNumber: phoneNumber,
        yearOfStudy: yearOfStudy, department: department, studentCode: studentCode,
      );
      state = state.copyWith(isLoading: false, user: updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordReset(email);
  }

  Future<void> createFacultyAccount({
    required String email,
    required String password,
    required String facultyFirestoreId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createFacultyAccount(
        email: email,
        password: password,
        facultyFirestoreId: facultyFirestoreId,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  /// Creates faculty account with auto-generated demo password + sends reset email.
  /// Returns the demo password string so admin can display/copy it.
  Future<String?> createFacultyWithDemoPassword({
    required String email,
    required String name,
    required String facultyFirestoreId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final demo = await _repository.createFacultyAccountWithDemoPassword(
        email: email,
        name: name,
        facultyFirestoreId: facultyFirestoreId,
      );
      state = state.copyWith(isLoading: false);
      return demo;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
      return null;
    }
  }

  Future<void> sendFacultyPasswordReset(String email) async {
    await _repository.sendFacultyPasswordReset(email);
  }

  Future<void> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.changeOwnPassword(
          currentPassword: currentPassword, newPassword: newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onFailed,
  }) async {
    // Phone auth not available in simplified repo — show error
    onFailed('Phone sign-in is not configured. Please use email/password.');
  }

  Future<void> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    state = state.copyWith(isLoading: false,
        error: 'Phone sign-in is not configured. Please use email/password.');
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
