import '../utils/app_environment.dart';

abstract final class SupabaseConstants {
  static String get url => AppEnvironment.supabaseUrl;
  static String get anonKey => AppEnvironment.supabaseAnonKey;

  static bool get isConfigured => AppEnvironment.hasSupabaseConfig;
}
