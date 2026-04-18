import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../domain/entities/community_message.dart';
import '../../domain/entities/faculty.dart';
import 'audio_service.dart';

// flutter_local_notifications is not supported on web — import conditionally
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) 'package:profhere/core/stubs/notifications_stub.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin? _plugin;
  static FlutterLocalNotificationsPlugin get _p =>
      _plugin ??= FlutterLocalNotificationsPlugin();

  static final Map<String, DateTime> _lastNotified = {};
  static const _debounce = Duration(seconds: 5); // reduced from 30s — allow more frequent notifications

  static bool isCommunityOpen = false;
  static String? currentUserId;
  static String? currentUserName;

  // ── Channel IDs ────────────────────────────────────────────────────────────
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
      await _p.initialize(settings);

      final androidPlugin = _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId, _channelName,
          description: 'New messages in Community Chat',
          importance: Importance.defaultImportance,
          playSound: false, // audio handled by AudioService
          enableVibration: false,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _mentionId, _mentionName,
          description: 'When someone mentions you in Community Chat',
          importance: Importance.high,
          playSound: false,
          enableVibration: true,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _facultyChannel, _facultyChName,
          description: 'Status updates from faculty you follow',
          importance: Importance.high,
          playSound: false,
          enableVibration: true,
        ),
      );
    } catch (e) {
      debugPrint('Notification service not available: $e');
    }
  }

  // ── Faculty status change ──────────────────────────────────────────────────

  /// Call when a subscribed faculty changes status.
  static Future<void> notifyFacultyStatusChange({
    required String facultyName,
    required FacultyStatus newStatus,
    required bool notificationsEnabled,
  }) async {
    if (kIsWeb) return;
    if (!notificationsEnabled) return;

    // Debounce per faculty
    final key = 'faculty_$facultyName';
    final last = _lastNotified[key];
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 10)) {
      return;
    }
    _lastNotified[key] = DateTime.now();

    // ── Play audio based on new status ──────────────────────────────────────
    final sound = switch (newStatus) {
      FacultyStatus.available    => AppSound.facultyAvailable,
      FacultyStatus.busy         => AppSound.facultyBusy,
      FacultyStatus.inLecture    => AppSound.facultyBusy,
      FacultyStatus.meeting      => AppSound.facultyBusy,
      FacultyStatus.away         => AppSound.facultyAway,
      FacultyStatus.notAvailable => AppSound.facultyAway,
      FacultyStatus.onHoliday    => AppSound.facultyAway,
      FacultyStatus.custom       => AppSound.facultyStatusChange,
    };
    AudioService.play(sound);

    // ── Push notification ────────────────────────────────────────────────────
    try {
      final body = switch (newStatus) {
        FacultyStatus.available    => '$facultyName is now Available — visit now!',
        FacultyStatus.busy         => '$facultyName is Busy right now.',
        FacultyStatus.inLecture    => '$facultyName is In Lecture.',
        FacultyStatus.meeting      => '$facultyName is In a Meeting.',
        FacultyStatus.away         => '$facultyName is Away.',
        FacultyStatus.notAvailable => '$facultyName is Not Available.',
        FacultyStatus.onHoliday    => '$facultyName is On Holiday.',
        FacultyStatus.custom       => '$facultyName updated their status.',
      };

      await _p.show(
        facultyName.hashCode,
      '${_statusTitle(newStatus)} — $facultyName',
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _facultyChannel, _facultyChName,
            importance: Importance.high,
            priority: Priority.high,
            playSound: false,
            styleInformation: BigTextStyleInformation(body),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Faculty notification failed: $e');
    }
  }

  static String _statusTitle(FacultyStatus s) => switch (s) {
    FacultyStatus.available    => 'Faculty Available',
    FacultyStatus.busy         => 'Faculty Busy',
    FacultyStatus.inLecture    => 'In Lecture',
    FacultyStatus.meeting      => 'In Meeting',
    FacultyStatus.away         => 'Faculty Away',
    FacultyStatus.notAvailable => 'Not Available',
    FacultyStatus.onHoliday    => 'On Holiday',
    FacultyStatus.custom       => 'Status Update',
  };

  // ── Community messages ─────────────────────────────────────────────────────

  static Future<void> onNewMessage({
    required CommunityMessage msg,
    required bool notificationsEnabled,
  }) async {
    if (kIsWeb) return;
    if (msg.senderId == currentUserId) return;
    if (msg.status != MessageStatus.visible) return;
    if (isCommunityOpen) return;

    final isMention = currentUserName != null &&
        msg.text
            .toLowerCase()
            .contains('@${currentUserName!.split(' ').first.toLowerCase()}');

    if (!isMention && !notificationsEnabled) return;

    // Debounce regular messages per sender
    final lastTime = _lastNotified[msg.senderId];
    if (!isMention &&
        lastTime != null &&
        DateTime.now().difference(lastTime) < _debounce) {
      return;
    }
    _lastNotified[msg.senderId] = DateTime.now();

    // ── Audio ────────────────────────────────────────────────────────────────
    AudioService.play(
      isMention ? AppSound.communityMention : AppSound.communityMessage,
    );

    // ── Push notification ────────────────────────────────────────────────────
    try {
      if (isMention) {
        await _showMentionNotification(msg);
      } else {
        await _showMessageNotification(msg);
      }
    } catch (_) {}
  }

  static Future<void> _showMentionNotification(CommunityMessage msg) async {
    final sender = msg.isAnonymous ? 'Someone' : msg.senderName;
    await _p.show(
      msg.id.hashCode,
      '$sender mentioned you',
      msg.text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _mentionId, _mentionName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(msg.text),
          groupKey: 'community_mentions',
        ),
      ),
    );
  }

  static Future<void> _showMessageNotification(CommunityMessage msg) async {
    final sender = msg.isAnonymous ? 'Anonymous' : msg.senderName;
    await _p.show(
      msg.senderId.hashCode,
      'Community Chat — $sender',
      msg.text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          styleInformation: BigTextStyleInformation(msg.text),
          groupKey: 'community_messages',
        ),
      ),
    );
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _p.cancelAll();
    } catch (_) {}
  }
}
