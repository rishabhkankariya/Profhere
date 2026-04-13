import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:profhere/core/services/notification_service.dart';
import 'package:profhere/core/services/permission_service.dart';
import 'package:profhere/core/services/widget_service.dart';
import 'package:profhere/core/theme/app_theme.dart';
import 'package:profhere/data/datasources/local/hive_service.dart';
import 'package:profhere/data/mock/mock_data_seeder.dart';
import 'package:profhere/domain/entities/faculty.dart';
import 'package:profhere/presentation/navigation/app_router.dart';
import 'package:profhere/presentation/providers/auth_provider.dart';
import 'package:profhere/presentation/providers/faculty_provider.dart';
import 'package:profhere/presentation/providers/prefs_provider.dart';
import 'package:profhere/presentation/providers/subscription_provider.dart';
import 'package:profhere/presentation/screens/onboarding/permission_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Hive kept only for local settings (widget prefs, subscriptions, user prefs)
  await HiveService.initSettingsOnly();
  await WidgetService.init();
  await NotificationService.init();
  // Seed initial Firestore data if empty (runs once)
  await MockDataSeeder.seedIfEmpty();
  runApp(const ProviderScope(child: ProfHereApp()));
}

class ProfHereApp extends ConsumerStatefulWidget {
  const ProfHereApp({super.key});
  @override
  ConsumerState<ProfHereApp> createState() => _ProfHereAppState();
}

class _ProfHereAppState extends ConsumerState<ProfHereApp>
    with WidgetsBindingObserver {
  bool _permissionsDone = false;

  // Track previous faculty statuses to detect changes for notifications
  final Map<String, FacultyStatus> _prevStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HomeWidget.widgetClicked.listen(_handleWidgetTap);
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── App lifecycle: sync widget → Hive when app comes to foreground ────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWidgetStatusToApp();
    }
  }

  /// Reads status written by the widget broadcast receiver and syncs to Hive.
  Future<void> _syncWidgetStatusToApp() async {
    if (kIsWeb) return;
    final user = ref.read(authNotifierProvider).user;
    if (user == null || user.role.name != 'faculty') return;

    final widgetStatus = await WidgetService.readWidgetStatus();
    if (widgetStatus == null) return;

    // Get current status from Hive
    final current = await ref.read(facultyRepositoryProvider).getFacultyById(user.id);
    if (current == null) return;

    // Only update if widget has a different status
    if (current.status != widgetStatus) {
      await ref.read(facultyNotifierProvider.notifier).updateStatus(user.id, widgetStatus);
    }
  }

  Future<void> _checkFirstLaunch() async {
    if (kIsWeb) {
      setState(() => _permissionsDone = true);
      return;
    }
    final alreadyAsked = HiveService.settings.get('permissions_asked') as bool? ?? false;
    if (alreadyAsked) setState(() => _permissionsDone = true);
  }

  Future<void> _onPermissionsDone() async {
    await HiveService.settings.put('permissions_asked', true);
    if (mounted) setState(() => _permissionsDone = true);
  }

  // ── Widget tap handler (legacy URI path — kept for safety) ────────────────
  void _handleWidgetTap(Uri? uri) async {
    if (uri == null) return;
    final status = WidgetService.statusFromUri(uri);
    if (status == null) return;
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    await ref.read(facultyNotifierProvider.notifier).updateStatus(user.id, status);
    await WidgetService.updateStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // ── Auth changes: sync widget login/logout ────────────────────────────
    ref.listen<AuthState>(authNotifierProvider, (_, next) async {
      NotificationService.currentUserId   = next.user?.id;
      NotificationService.currentUserName = next.user?.name;

      if (next.user?.role.name == 'faculty') {
        final facultyId = next.user!.id;
        final faculty = await ref.read(facultyRepositoryProvider).getFacultyById(facultyId);
        if (faculty != null) {
          await WidgetService.onFacultyLogin(
            facultyId: facultyId,
            facultyName: faculty.name,
            status: faculty.status,
          );
        }
      } else if (next.user == null) {
        await WidgetService.onFacultyLogout();
        _prevStatuses.clear();
      }
    });

    // ── Faculty list stream: widget sync + subscription notifications ─────
    ref.listen<AsyncValue<List<Faculty>>>(facultyListProvider, (prev, next) async {
      final user = ref.read(authNotifierProvider).user;

      next.whenData((list) async {
        // 1. Keep widget in sync for faculty users
        if (user?.role.name == 'faculty') {
          final me = list.where((f) => f.id == user!.id).firstOrNull;
          if (me != null) await WidgetService.updateStatus(me.status);
        }

        // 2. Subscription notifications for student users
        if (user?.role.name == 'student') {
          final subscribed = ref.read(subscriptionProvider);
          final prefs      = ref.read(userPrefsProvider);
          if (!prefs.notificationsEnabled) return;

          for (final faculty in list) {
            if (!subscribed.contains(faculty.id)) continue;

            final prevStatus = _prevStatuses[faculty.id];
            // Only notify if status actually changed
            if (prevStatus != null && prevStatus != faculty.status) {
              await NotificationService.notifyFacultyStatusChange(
                facultyName: faculty.name,
                newStatus: faculty.status,
                notificationsEnabled: true,
              );
            }
            _prevStatuses[faculty.id] = faculty.status;
          }
        }
      });
    });

    return MaterialApp.router(
      title: 'ProfHere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        if (!_permissionsDone) {
          return PermissionScreen(onDone: _onPermissionsDone);
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
