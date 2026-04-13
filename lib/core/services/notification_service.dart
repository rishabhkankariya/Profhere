import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/entities/community_message.dart';
import '../../domain/entities/faculty.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static final Map<String, DateTime> _lastNotified = {};
  static const _debounce = Duration(seconds: 30);

  static bool isCommunityOpen = false;
  static String? currentUserId;
  static String? currentUserName;

  static const _channelId      = 'community_chat';
  static const _channelName    = 'Community Chat';
  static const _mentionId      = 'community_mention';
  static const _mentionName    = 'Mentions';
  static const _facultyChannel = 'faculty_status';
  static const _facultyChName  = 'Faculty Status';

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId, _channelName,
          description: 'New messages in Community Chat',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: false,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _mentionId, _mentionName,
          description: 'When someone mentions you in Community Chat',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      // Faculty status channel — for subscribed faculty alerts
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _facultyChannel, _facultyChName,
          description: 'Status updates from faculty you follow',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    } catch (e) {
      debugPrint('Notification service not available: $e');
    }
  }

  /// Call when a subscribed faculty changes status.
  /// Only fires if the student has notifications enabled.
  static Future<void> notifyFacultyStatusChange({
    required String facultyName,
    required FacultyStatus newStatus,
    required bool notificationsEnabled,
  }) async {
    if (kIsWeb) return;
    if (!notificationsEnabled) return;

    // Debounce per faculty — avoid spam on rapid changes
    final key = 'faculty_$facultyName';
    final last = _lastNotified[key];
    if (last != null && DateTime.now().difference(last) < const Duration(seconds: 10)) return;
    _lastNotified[key] = DateTime.now();

    try {
      final body = switch (newStatus) {
        FacultyStatus.available    => '$facultyName is now Available — visit now!',
        FacultyStatus.busy         => '$facultyName is Busy right now.',
        FacultyStatus.inLecture    => '$facultyName is In Lecture.',
        FacultyStatus.meeting      => '$facultyName is In a Meeting.',
        FacultyStatus.away         => '$facultyName is Away.',
        FacultyStatus.notAvailable => '$facultyName is Not Available.',
      };

      await _plugin.show(
        facultyName.hashCode,
        'Faculty Update',
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _facultyChannel, _facultyChName,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Faculty notification failed: $e');
    }
  }

  /// Call this when a new message arrives in the community stream.
  /// [notificationsEnabled] comes from the user's prefs.
  static Future<void> onNewMessage({
    required CommunityMessage msg,
    required bool notificationsEnabled,
  }) async {
    // Skip on web
    if (kIsWeb) return;
    
    // Never notify for own messages
    if (msg.senderId == currentUserId) return;
    // Never notify for removed/flagged messages
    if (msg.status != MessageStatus.visible) return;
    // Never notify if community screen is open
    if (isCommunityOpen) return;

    final isMention = currentUserName != null &&
        msg.text.toLowerCase().contains('@${currentUserName!.split(' ').first.toLowerCase()}');

    // For regular messages, respect the notifications preference
    if (!isMention && !notificationsEnabled) return;

    // Debounce — don't spam from the same sender
    final lastTime = _lastNotified[msg.senderId];
    if (!isMention && lastTime != null && DateTime.now().difference(lastTime) < _debounce) {
      return;
    }
    _lastNotified[msg.senderId] = DateTime.now();

    try {
      if (isMention) {
        await _showMentionNotification(msg);
      } else {
        await _showMessageNotification(msg);
      }
    } catch (e) {
      // Silently fail if notification fails
    }
  }

  static Future<void> _showMentionNotification(CommunityMessage msg) async {
    final senderDisplay = msg.isAnonymous ? 'Someone' : msg.senderName;
    await _plugin.show(
      msg.id.hashCode,
      '📣 $senderDisplay mentioned you',
      msg.text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _mentionId,
          _mentionName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(msg.text),
          groupKey: 'community_mentions',
        ),
      ),
    );
  }

  static Future<void> _showMessageNotification(CommunityMessage msg) async {
    final senderDisplay = msg.isAnonymous ? 'Anonymous' : msg.senderName;
    await _plugin.show(
      // Use a stable ID per sender so messages from same person update the same notification
      msg.senderId.hashCode,
      'Community Chat — $senderDisplay',
      msg.text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(msg.text),
          groupKey: 'community_messages',
          setAsGroupSummary: false,
        ),
      ),
    );
  }

  /// Cancel all community notifications (call when user opens the chat)
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    
    try {
      await _plugin.cancelAll();
    } catch (e) {
      // Silently fail if not supported
    }
  }
}
