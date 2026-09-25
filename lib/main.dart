import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/app_environment.dart';
import 'data/services/notification_service.dart';
import 'data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeDependencies();

  runApp(const ProviderScope(child: ProfHereApp()));
}

Future<void> _initializeDependencies() async {
  try {
    await AppEnvironment.load();
    await NotificationService.init();
    await SupabaseService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Startup initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
