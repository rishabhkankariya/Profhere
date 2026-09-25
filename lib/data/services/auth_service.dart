import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/database_constants.dart';
import '../../domain/entities/app_user.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentAuthUser => _client.auth.currentUser;

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{'role': role.value, 'full_name': fullName},
      );

      final user = response.user;
      if (user == null) {
        throw StateError('Supabase sign up did not return a user.');
      }

      final appUser = await _createDatabaseUser(
        authUser: user,
        fullName: fullName,
        role: role,
      );

      if (role == UserRole.faculty || role == UserRole.admin) {
        await _ensureFacultyProfile(appUser);
      }

      return appUser;
    } catch (error) {
      throw _mapAuthError(error);
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw StateError('Supabase sign in did not return a user.');
      }

      return (await fetchUserByAuthId(user.id)) ?? UserModel.fromAuthUser(user);
    } catch (error) {
      throw _mapAuthError(error);
    }
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> resendSignupConfirmation(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } catch (error) {
      throw _mapAuthError(error);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = currentAuthUser;
    if (user == null) {
      return null;
    }

    try {
      return (await fetchUserByAuthId(user.id)) ?? UserModel.fromAuthUser(user);
    } catch (_) {
      // In case of timeout or failure, fallback to minimal auth user
      return UserModel.fromAuthUser(user);
    }
  }

  Future<UserModel?> fetchUserByAuthId(String authId) async {
    final response = await _client
        .from(DatabaseConstants.usersTable)
        .select()
        .eq('auth_id', authId)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));

    if (response == null) {
      return null;
    }

    return UserModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<UserModel> _createDatabaseUser({
    required User authUser,
    required String fullName,
    required UserRole role,
  }) async {
    final response = await _client
        .from(DatabaseConstants.usersTable)
        .insert(<String, dynamic>{
          'full_name': fullName,
          'email': authUser.email ?? '',
          'role': role.value,
          'auth_id': authUser.id,
        })
        .select()
        .single()
        .timeout(const Duration(seconds: 5));

    return UserModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> _ensureFacultyProfile(UserModel user) {
    return _client
        .from(DatabaseConstants.facultyTable)
        .upsert(<String, dynamic>{
          'user_id': user.id,
          'name': user.name,
          'cabin': 'Not assigned',
          'department': 'General',
        })
        .timeout(const Duration(seconds: 5));
  }

  AuthFlowException _mapAuthError(Object error) {
    if (error is AuthFlowException) {
      return error;
    }

    final rawMessage = error is AuthException
        ? error.message
        : error.toString();
    final normalized = rawMessage.toLowerCase();

    if (normalized.contains('email not confirmed') ||
        normalized.contains('email_not_confirmed')) {
      return const AuthFlowException(
        'Email not confirmed yet. Open the confirmation email first, then log in.',
      );
    }

    if (normalized.contains('invalid login credentials')) {
      return const AuthFlowException(
        'Invalid email or password. Please check your credentials and try again.',
      );
    }

    if (normalized.contains('user already registered')) {
      return const AuthFlowException(
        'This email is already registered. Try logging in instead.',
      );
    }

    if (normalized.contains('rate limit') || normalized.contains('email limit')) {
      return const AuthFlowException(
        'Security threshold reached. Please wait a few minutes before trying again.',
      );
    }

    return AuthFlowException(rawMessage);
  }
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}
