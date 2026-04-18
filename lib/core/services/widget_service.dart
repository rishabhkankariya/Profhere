import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:home_widget/home_widget.dart';
import '../../domain/entities/faculty.dart';

/// Manages the Android home screen widget for faculty quick status.
/// The widget shows the logged-in faculty's name, current status,
/// and three quick-change buttons (Available / Busy / In Lecture).
class WidgetService {
  static const _widgetName  = 'ProfHereWidget';
  // Keys written to HomeWidget shared storage
  static const _keyLoggedIn    = 'faculty_logged_in';
  static const _keyFacultyId   = 'faculty_id';
  static const _keyFacultyName = 'faculty_name';
  static const _keyStatus      = 'faculty_status';
  static const _keyStatusColor = 'faculty_status_color';

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      // widgetClicked stream is handled in main.dart
      HomeWidget.widgetClicked.listen((_) {});
    } catch (e) {
      debugPrint('Widget service not available: $e');
    }
  }

  /// Called when the faculty logs in — writes data and refreshes widget.
  static Future<void> onFacultyLogin({
    required String facultyId,
    required String facultyName,
    required FacultyStatus status,
  }) async {
    if (kIsWeb) return;
    
    try {
      await _write(_keyLoggedIn,    'true');
      await _write(_keyFacultyId,   facultyId);
      await _write(_keyFacultyName, facultyName);
      await _write(_keyStatus,      status.label);
      await _write(_keyStatusColor, _colorHex(status));
      await _refresh();
    } catch (e) {
      // Silently fail on unsupported platforms
    }
  }

  /// Called when the faculty logs out.
  static Future<void> onFacultyLogout() async {
    if (kIsWeb) return;
    
    try {
      await _write(_keyLoggedIn,    'false');
      await _write(_keyFacultyName, 'Not logged in');
      await _write(_keyStatus,      '--');
      await _write(_keyStatusColor, '#94A3B8');
      await _refresh();
    } catch (e) {
      // Silently fail on unsupported platforms
    }
  }

  /// Called after a status change — updates widget without full re-login.
  static Future<void> updateStatus(FacultyStatus status, {String? customStatusText}) async {
    if (kIsWeb) return;
    try {
      await _write(_keyStatus,      status == FacultyStatus.custom && customStatusText != null
          ? customStatusText
          : status.label);
      await _write(_keyStatusColor, _colorHex(status));
      await _refresh();
    } catch (e) {
      // Silently fail on unsupported platforms
    }
  }

  /// Reads the status last written by the widget broadcast receiver.
  /// Call this on app foreground to sync widget changes into Hive.
  static Future<FacultyStatus?> readWidgetStatus() async {
    if (kIsWeb) return null;
    try {
      final raw = await HomeWidget.getWidgetData<String>(_keyStatus);
      if (raw == null) return null;
      return FacultyStatus.values.firstWhere(
        (s) => s.label == raw,
        orElse: () => FacultyStatus.available,
      );
    } catch (_) {
      return null;
    }
  }

  /// Reads the faculty ID stored in widget SharedPreferences.
  static Future<String?> readWidgetFacultyId() async {
    if (kIsWeb) return null;
    try {
      return await HomeWidget.getWidgetData<String>(_keyFacultyId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _write(String key, String value) =>
      HomeWidget.saveWidgetData<String>(key, value);

  static Future<void> _refresh() =>
      HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
        qualifiedAndroidName: 'com.profhere.profhere.$_widgetName',
      );

  static String _colorHex(FacultyStatus s) {
    switch (s) {
      case FacultyStatus.available:    return '#16A34A';
      case FacultyStatus.busy:         return '#D97706';
      case FacultyStatus.inLecture:    return '#DC2626';
      case FacultyStatus.meeting:      return '#7C3AED';
      case FacultyStatus.away:         return '#6B7280';
      case FacultyStatus.notAvailable: return '#374151';
      case FacultyStatus.onHoliday:    return '#0891B2';
      case FacultyStatus.custom:       return '#7C3AED';
    }
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// Returns the status from a widget tap URI.
  static FacultyStatus? statusFromUri(Uri uri) {
    final value = uri.queryParameters['value'];
    switch (value) {
      case 'available':    return FacultyStatus.available;
      case 'busy':         return FacultyStatus.busy;
      case 'inLecture':    return FacultyStatus.inLecture;
      case 'meeting':      return FacultyStatus.meeting;
      case 'away':         return FacultyStatus.away;
      case 'notAvailable': return FacultyStatus.notAvailable;
      case 'onHoliday':    return FacultyStatus.onHoliday;
      case 'custom':       return FacultyStatus.custom;
      default:             return null;
    }
  }
}
