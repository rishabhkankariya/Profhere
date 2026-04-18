import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestNotifications() async {
    if (kIsWeb) return false;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }
}
