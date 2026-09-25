import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth_gate.dart';
import 'presentation/widgets/app_runtime_listener.dart';

class ProfHereApp extends StatelessWidget {
  const ProfHereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const AppRuntimeListener(child: AuthGate()),
    );
  }
}
