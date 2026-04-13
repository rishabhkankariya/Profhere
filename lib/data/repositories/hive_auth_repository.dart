import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/hive_service.dart';
import '../models/user_model.dart';

class HiveAuthRepository implements AuthRepository {
  static const _uuid = Uuid();
  static const _sessionUserIdKey = 'sessionUserId';

  final _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;
  bool _sessionRestored = false;

  Future<void> _ensureSessionRestored() async {
    if (_sessionRestored) return;
    _sessionRestored = true;

    final id = HiveService.settings.get(_sessionUserIdKey) as String?;
    if (id == null) return;

    final model = HiveService.users.get(id);
    if (model == null) {
      await HiveService.settings.delete(_sessionUserIdKey);
      return;
    }

    _currentUser = model.toEntity();
  }

  Future<void> _persistSession(String? userId) async {
    if (userId == null || userId.isEmpty) {
      await HiveService.settings.delete(_sessionUserIdKey);
      return;
    }
    await HiveService.settings.put(_sessionUserIdKey, userId);
  }

  @override
  Stream<User?> authStateChanges() async* {
    await _ensureSessionRestored();
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  Future<User?> getCurrentUser() async {
    await _ensureSessionRestored();
    return _currentUser;
  }

  @override
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final users = HiveService.users.values.where(
      (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password,
    );

    if (users.isEmpty) {
      throw Exception('Invalid email or password');
    }

    final userModel = users.first;
    final updatedUser = userModel.copyWith(lastLoginAt: DateTime.now());
    await HiveService.users.put(userModel.id, updatedUser);
    
    _currentUser = updatedUser.toEntity();
    await _persistSession(updatedUser.id);
    _authStateController.add(_currentUser);

    return _currentUser;
  }

  @override
  Future<User?> register(String name, String email, String password, {String? studentCode}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final existingUser = HiveService.users.values.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );

    if (existingUser) {
      throw Exception('Email already registered');
    }

    final userModel = UserModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      roleIndex: UserRole.student.index,
      studentCode: studentCode,
      createdAt: DateTime.now(),
      password: password,
    );

    await HiveService.users.put(userModel.id, userModel);

    _currentUser = userModel.toEntity();
    await _persistSession(userModel.id);
    _authStateController.add(_currentUser);

    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await _persistSession(null);
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
