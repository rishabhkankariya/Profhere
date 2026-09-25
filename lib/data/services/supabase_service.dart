import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_constants.dart';

final class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static bool _initialized = false;
  static Object? _initializationError;

  static Future<void> initialize() async {
    if (_initialized || !SupabaseConstants.isConfigured) {
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConstants.url,
        anonKey: SupabaseConstants.anonKey,
      );
      _initialized = true;
      _initializationError = null;
    } catch (error) {
      _initialized = false;
      _initializationError = error;
    }
  }

  static bool get isInitialized => _initialized;

  static bool get isConfigured => SupabaseConstants.isConfigured;

  static Object? get initializationError => _initializationError;

  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  static GoTrueClient? get auth => client?.auth;

  static SupabaseStorageClient? get storage => client?.storage;

  static SupabaseQueryBuilder from(String table) {
    final supabaseClient = client;
    if (supabaseClient == null) {
      throw StateError(
        'Supabase has not been initialized. Add SUPABASE_URL and '
        'SUPABASE_ANON_KEY to the .env file before accessing the client.',
      );
    }

    return supabaseClient.from(table);
  }

  static Future<List<Map<String, dynamic>>> fetchList({
    required String table,
    String columns = '*',
    int? limit,
  }) async {
    final query = from(table).select(columns);
    final response = limit == null ? await query : await query.limit(limit);

    return response
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>?> fetchSingle({
    required String table,
    String columns = '*',
  }) async {
    final response = await from(table).select(columns).maybeSingle();
    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  static Future<bool> testConnection({String table = 'profiles'}) async {
    try {
      await fetchList(table: table, limit: 1);
      return true;
    } catch (_) {
      return false;
    }
  }
}
