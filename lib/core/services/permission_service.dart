import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestNotifications() async {
    if (kIsWeb) return false;
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.areNotificationsEnabled();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestCamera() async {
    if (kIsWeb) return false;
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasCameraPermission() async {
    if (kIsWeb) return false;
    try {
      return await Permission.camera.isGranted;
    } catch (_) {
      return false;
    }
  }
}
