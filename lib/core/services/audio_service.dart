import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// All sound events in the app.
enum AppSound {
  /// Played when a student subscribes to a faculty
  subscribe,

  /// Played when a student unsubscribes from a faculty
  unsubscribe,

  /// Played when a subscribed faculty becomes Available
  facultyAvailable,

  /// Played when a subscribed faculty becomes Busy / In Lecture / Meeting
  facultyBusy,

  /// Played when a subscribed faculty becomes Away / Not Available
  facultyAway,

  /// Played for any other faculty status change
  facultyStatusChange,

  /// Played when a new community message arrives (not a mention)
  communityMessage,

  /// Played when the user is @mentioned in community
  communityMention,

  /// Played on successful action (join queue, save, etc.)
  success,

  /// Played on error / failure
  error,
}

class AudioService {
  AudioService._();

  static final _rng = Random();

  // Two notification sounds from assets — picked randomly for status alerts
  static const _notifSounds = [
    'soynoviembre-short-digital-notification-alert-440353.mp3',
    'universfield-new-notification-022-370046.mp3',
  ];

  // Dedicated pool: one player per logical role so overlapping sounds don't cut each other
  static final _players = <String, AudioPlayer>{};

  static AudioPlayer _player(String key) {
    return _players.putIfAbsent(key, () {
      final p = AudioPlayer();
      p.setReleaseMode(ReleaseMode.stop);
      return p;
    });
  }

  /// Play a sound for the given [event].
  /// Safe to call from anywhere — silently no-ops on web or on error.
  static Future<void> play(AppSound event) async {
    if (kIsWeb) return;
    try {
      switch (event) {
        // ── Subscribe / Unsubscribe ──────────────────────────────────────
        case AppSound.subscribe:
          await _playAsset(_player('ui'), _notifSounds[0], volume: 0.7);

        case AppSound.unsubscribe:
          await _playAsset(_player('ui'), _notifSounds[1], volume: 0.5);

        // ── Faculty available → high-priority, random sound ──────────────
        case AppSound.facultyAvailable:
          await _playAsset(_player('faculty'), _randomNotif(), volume: 1.0);

        // ── Faculty busy / in lecture / meeting → softer alert ───────────
        case AppSound.facultyBusy:
          await _playAsset(_player('faculty'), _notifSounds[1], volume: 0.65);

        // ── Faculty away / not available → subtle ────────────────────────
        case AppSound.facultyAway:
          await _playAsset(_player('faculty'), _notifSounds[0], volume: 0.4);

        // ── Any other status change → random, medium volume ──────────────
        case AppSound.facultyStatusChange:
          await _playAsset(_player('faculty'), _randomNotif(), volume: 0.6);

        // ── Community message → quiet ────────────────────────────────────
        case AppSound.communityMessage:
          await _playAsset(_player('chat'), _notifSounds[1], volume: 0.45);

        // ── @mention → louder, random ────────────────────────────────────
        case AppSound.communityMention:
          await _playAsset(_player('chat'), _randomNotif(), volume: 0.9);

        // ── Success / Error (UI feedback) ────────────────────────────────
        case AppSound.success:
          await _playAsset(_player('ui'), _notifSounds[0], volume: 0.55);

        case AppSound.error:
          await _playAsset(_player('ui'), _notifSounds[1], volume: 0.55);
      }
    } catch (e) {
      debugPrint('[AudioService] play($event) failed: $e');
    }
  }

  static String _randomNotif() =>
      _notifSounds[_rng.nextInt(_notifSounds.length)];

  static Future<void> _playAsset(
    AudioPlayer player,
    String assetPath, {
    double volume = 1.0,
  }) async {
    await player.setVolume(volume);
    await player.play(AssetSource(assetPath));
  }

  /// Release all players — call on app dispose if needed.
  static Future<void> disposeAll() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}
