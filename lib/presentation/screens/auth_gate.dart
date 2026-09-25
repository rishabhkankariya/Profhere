import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../providers/auth_provider.dart';
import 'faculty_dashboard_screen.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'student_home_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        switch (user.role) {
          case UserRole.faculty:
          case UserRole.admin:
            return const FacultyDashboardScreen();
          case UserRole.student:
            return const StudentHomeScreen();
        }
      },
      loading: () => const SplashScreen(),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to restore session.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
