import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:profhere/domain/entities/user.dart';
import 'package:profhere/presentation/providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../../presentation/providers/faculty_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../screens/auth/force_change_password_screen.dart';
import '../screens/faculty/faculty_list_screen.dart';
import '../screens/faculty/faculty_detail_screen.dart';
import '../screens/faculty/faculty_dashboard_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/community/faculty_community_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/todo/todo_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/faculty/faculty_location_settings_screen.dart';
import '../screens/student/student_location_access_screen.dart';
import '../screens/admin/admin_location_access_screen.dart';

class AppRoutes {
  static const splash                  = '/';
  static const login                   = '/login';
  static const register                = '/register';
  static const phoneAuth               = '/phone-auth';
  static const forceChangePass         = '/force-change-password';
  static const faculties               = '/faculties';
  static const facultyDetail           = '/faculty/:id';
  static const facultyDashboard        = '/faculty-dashboard';
  static const admin                   = '/admin';
  static const community               = '/community';
  static const facultyCommunity        = '/faculty-community';
  static const editProfile             = '/edit-profile';
  static const todo                    = '/todo';
  static const events                  = '/events';
  static const facultyLocationSettings = '/faculty-location-settings/:facultyId';
  static const studentLocationAccess   = '/student-location-access/:facultyId';
  static const adminLocationAccess     = '/admin-location-access';
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
  const publicRoutes = {AppRoutes.splash, AppRoutes.login, AppRoutes.register, AppRoutes.phoneAuth};

  if (!publicRoutes.contains(loc) && user == null) return AppRoutes.login;

  // Faculty with mustChangePassword must go to force-change screen
  if (user != null && user.mustChangePassword &&
      loc != AppRoutes.forceChangePass) {
    return AppRoutes.forceChangePass;
  }

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
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) => _redirectForAuth(ref, state),
    routes: [
      GoRoute(path: AppRoutes.splash,           builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,            builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register,         builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.phoneAuth,        builder: (_, __) => const PhoneAuthScreen()),
      GoRoute(path: AppRoutes.forceChangePass,  builder: (_, __) => const ForceChangePasswordScreen()),
      GoRoute(path: AppRoutes.faculties,        builder: (_, __) => const FacultyListScreen()),
      GoRoute(path: AppRoutes.facultyDetail,    builder: (_, s)  => FacultyDetailScreen(facultyId: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.facultyDashboard, builder: (_, __) => const FacultyDashboardScreen()),
      GoRoute(path: AppRoutes.admin,            builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: AppRoutes.community,        builder: (_, __) => const CommunityScreen()),
      GoRoute(path: AppRoutes.facultyCommunity, builder: (_, __) => const FacultyCommunityScreen()),
      GoRoute(path: AppRoutes.editProfile,      builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.todo,             builder: (_, __) => const TodoScreen()),
      GoRoute(path: AppRoutes.events,           builder: (_, __) => const EventsScreen()),
      GoRoute(
        path: AppRoutes.facultyLocationSettings,
        builder: (_, s) => FacultyLocationSettingsScreen(
          facultyId: s.pathParameters['facultyId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.studentLocationAccess,
        builder: (_, s) {
          final facultyId = s.pathParameters['facultyId']!;
          return _StudentLocationAccessWrapper(facultyId: facultyId);
        },
      ),
      GoRoute(
        path: AppRoutes.adminLocationAccess,
        builder: (_, __) => const AdminLocationAccessScreen(),
      ),
    ],
  );
});

/// Wrapper that loads the Faculty entity then passes it to the screen.
class _StudentLocationAccessWrapper extends ConsumerWidget {
  final String facultyId;
  const _StudentLocationAccessWrapper({required this.facultyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(facultyByIdProvider(facultyId));
    return async.when(
      data: (faculty) => faculty == null
          ? const Scaffold(body: Center(child: Text('Faculty not found')))
          : StudentLocationAccessScreen(faculty: faculty),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
    );
  }
}
