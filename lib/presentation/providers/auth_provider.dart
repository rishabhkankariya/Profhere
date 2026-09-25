import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../domain/entities/app_user.dart';
import 'supabase_provider.dart';

final authServiceProvider = Provider<AuthService?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) {
    return null;
  }

  return AuthService(supabaseClient);
});

final authStateProvider = StreamProvider<UserModel?>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  if (authService == null) {
    yield null;
    return;
  }

  yield await authService.getCurrentUser();

  await for (final AuthState _ in authService.authStateChanges) {
    yield await authService.getCurrentUser();
  }
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({required String email, required String password}) async {
    final authService = ref.read(authServiceProvider);
    if (authService == null) {
      throw StateError('Supabase is not configured.');
    }

    state = const AsyncLoading();
    try {
      final user = await authService.signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final authService = ref.read(authServiceProvider);
    if (authService == null) {
      throw StateError('Supabase is not configured.');
    }

    state = const AsyncLoading();
    try {
      final user = await authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      state = AsyncValue.data(user);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    if (authService == null) {
      throw StateError('Supabase is not configured.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(authService.signOut);
  }

  Future<void> resendConfirmationEmail(String email) async {
    final authService = ref.read(authServiceProvider);
    if (authService == null) {
      throw StateError('Supabase is not configured.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => authService.resendSignupConfirmation(email),
    );
  }
}
