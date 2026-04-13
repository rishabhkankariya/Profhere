import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profhere/domain/entities/user.dart';
import 'package:profhere/presentation/providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../screens/faculty/faculty_list_screen.dart';
import '../screens/faculty/faculty_detail_screen.dart';
import '../screens/faculty/faculty_dashboard_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/profile/edit_profile_screen.dart';

class AppRoutes {
  static const splash          = '/';
  static const login           = '/login';
  static const register        = '/register';
  static const phoneAuth       = '/phone-auth';
  static const faculties       = '/faculties';
  static const facultyDetail   = '/faculty/:id';
  static const facultyDashboard= '/faculty-dashboard';
  static const admin           = '/admin';
  static const community       = '/community';
  static const editProfile     = '/edit-profile';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AuthRouteRefresh extends ChangeNotifier {
  void notifyAuthChanged() => notifyListeners();
}

String _homeRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:   return AppRoutes.admin;
    case UserRole.faculty: return AppRoutes.facultyDashboard;
    case UserRole.student: return AppRoutes.faculties;
  }
}

String? _redirectForAuth(Ref ref, GoRouterState state) {
  final user = ref.read(authNotifierProvider).user;
  final loc  = state.matchedLocation;
  const publicRoutes = {AppRoutes.splash, AppRoutes.login, AppRoutes.register};
  if (!publicRoutes.contains(loc) && user == null) return AppRoutes.login;
  if (user != null && (loc == AppRoutes.login || loc == AppRoutes.register)) {
    return _homeRouteForRole(user.role);
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = AuthRouteRefresh();
  ref.listen<AuthState>(authNotifierProvider, (_, __) => refresh.notifyAuthChanged());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirectForAuth(ref, state),
    routes: [
      GoRoute(path: AppRoutes.splash,           builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,            builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register,         builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.phoneAuth,        builder: (_, __) => const PhoneAuthScreen()),
      GoRoute(path: AppRoutes.faculties,        builder: (_, __) => const FacultyListScreen()),
      GoRoute(path: AppRoutes.facultyDetail,    builder: (_, s)  => FacultyDetailScreen(facultyId: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.facultyDashboard, builder: (_, __) => const FacultyDashboardScreen()),
      GoRoute(path: AppRoutes.admin,            builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: AppRoutes.community,        builder: (_, __) => const CommunityScreen()),
      GoRoute(path: AppRoutes.editProfile,      builder: (_, __) => const EditProfileScreen()),
    ],
  );
});
