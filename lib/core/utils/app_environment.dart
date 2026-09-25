import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/app_constants.dart';

abstract final class AppEnvironment {
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) {
      return;
    }

    await dotenv.load(fileName: '.env');
    _loaded = true;
  }

  static String get supabaseUrl =>
      dotenv.maybeGet(AppConstants.supabaseUrlKey) ?? '';

  static String get supabaseAnonKey =>
      dotenv.maybeGet(AppConstants.supabaseAnonKeyKey) ?? '';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
