// Stub for flutter_local_notifications on web.
// Must mirror every parameter used in notification_service.dart so dart2js compiles.

class FlutterLocalNotificationsPlugin {
  Future<bool?> initialize(dynamic settings,
      {dynamic onDidReceiveNotificationResponse}) async => false;
  Future<void> show(int id, String? title, String? body,
      dynamic notificationDetails, {String? payload}) async {}
  Future<void> cancelAll() async {}
  T? resolvePlatformSpecificImplementation<T>() => null;
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<bool?> requestNotificationsPermission() async => false;
  Future<bool?> areNotificationsEnabled() async => false;
  Future<void> createNotificationChannel(dynamic channel) async {}
}

class InitializationSettings {
  final dynamic android;
  final dynamic iOS;
  const InitializationSettings({this.android, this.iOS});
}

class AndroidInitializationSettings {
  final String defaultIcon;
  const AndroidInitializationSettings(this.defaultIcon);
}

class NotificationDetails {
  final dynamic android;
  const NotificationDetails({this.android});
}

class AndroidNotificationDetails {
  final String channelId;
  final String channelName;
  final dynamic importance;
  final dynamic priority;
  final dynamic styleInformation;
  final String? groupKey;
  final bool setAsGroupSummary;
  final bool playSound;
  final bool enableVibration;
  final dynamic largeIcon;
  const AndroidNotificationDetails(
    this.channelId,
    this.channelName, {
    this.importance,
    this.priority,
    this.styleInformation,
    this.groupKey,
    this.setAsGroupSummary = false,
    this.playSound = true,
    this.enableVibration = false,
    this.largeIcon,
  });
}

class AndroidNotificationChannel {
  final String id;
  final String name;
  final String? description;
  final dynamic importance;
  final bool playSound;
  final bool enableVibration;
  const AndroidNotificationChannel(
    this.id,
    this.name, {
    this.description,
    this.importance,
    this.playSound = true,
    this.enableVibration = false,
  });
}

/// Stub for DrawableResourceAndroidBitmap — Android-only, no-op on web.
class DrawableResourceAndroidBitmap {
  final String name;
  const DrawableResourceAndroidBitmap(this.name);
}

class BigTextStyleInformation {
  final String text;
  const BigTextStyleInformation(this.text);
}

class Importance {
  static const defaultImportance = Importance._('default');
  static const high = Importance._('high');
  const Importance._(String _);
}

class Priority {
  static const defaultPriority = Priority._('default');
  static const high = Priority._('high');
  const Priority._(String _);
}
