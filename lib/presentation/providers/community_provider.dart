import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/firestore_community_repository.dart';
import '../../domain/entities/community_message.dart';
import 'prefs_provider.dart';

final communityRepositoryProvider = Provider<FirestoreCommunityRepository>((ref) {
  return FirestoreCommunityRepository();
});

final communityMessagesProvider = StreamProvider<List<CommunityMessage>>((ref) {
  final repo  = ref.watch(communityRepositoryProvider);
  final prefs = ref.watch(userPrefsProvider);
  CommunityMessage? lastSeen;
  return repo.watch().handleError((_) {}).map((msgs) {
    if (msgs.isNotEmpty) {
      final latest = msgs.last;
      if (lastSeen == null || latest.id != lastSeen!.id) {
        lastSeen = latest;
        NotificationService.onNewMessage(
          msg: latest,
          notificationsEnabled: prefs.notificationsEnabled,
        );
      }
    }
    return msgs;
  });
});

/// Currently selected reply-to message
final replyToProvider = StateProvider<CommunityMessage?>((ref) => null);

class CommunityNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreCommunityRepository _repo;
  CommunityNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<bool> send({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    bool isAnonymous = false,
    String? senderAvatar,
    CommunityMessage? replyTo,
  }) async {
    if (text.trim().isEmpty) return false;
    state = const AsyncValue.loading();
    try {
      await _repo.sendMessage(
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        text: text.trim(),
        isAnonymous: isAnonymous,
        senderAvatar: senderAvatar,
        replyTo: replyTo,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> remove(String id) async {
    await _repo.removeMessage(id);
    state = const AsyncValue.data(null);
  }

  Future<bool> edit(String id, String newText) async {
    if (newText.trim().isEmpty) return false;
    state = const AsyncValue.loading();
    try {
      await _repo.editMessage(id, newText.trim());
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> togglePin(String id) async {
    await _repo.togglePin(id);
    state = const AsyncValue.data(null);
  }

  Future<void> addReaction(String messageId, String emoji, String userId) async {
    await _repo.addReaction(messageId, emoji, userId);
    state = const AsyncValue.data(null);
  }

  Future<void> removeReaction(String messageId, String emoji) async {
    await _repo.removeReaction(messageId, emoji);
    state = const AsyncValue.data(null);
  }

  // ── Faculty moderation ────────────────────────────────────────────────────

  Future<void> deleteMessage(String id) async {
    await _repo.deleteMessage(id);
    state = const AsyncValue.data(null);
  }

  Future<void> blockUser(String userId, String facultyId) async {
    await _repo.blockUser(userId, facultyId);
    state = const AsyncValue.data(null);
  }

  Future<void> unblockUser(String userId) async {
    await _repo.unblockUser(userId);
    state = const AsyncValue.data(null);
  }

  Future<void> restrictUser(String userId, String facultyId) async {
    await _repo.restrictUser(userId, facultyId);
    state = const AsyncValue.data(null);
  }

  Future<void> unrestrictUser(String userId) async {
    await _repo.unrestrictUser(userId);
    state = const AsyncValue.data(null);
  }
}

final communityNotifierProvider =
    StateNotifierProvider<CommunityNotifier, AsyncValue<void>>((ref) {
  return CommunityNotifier(ref.watch(communityRepositoryProvider));
});

// ── Blocked / restricted user streams ────────────────────────────────────────
// Use handleError so a Firestore permission-denied on these collections
// never crashes the community screen — it just returns an empty list.

final blockedUserIdsProvider = StreamProvider<List<String>>((ref) {
  return ref
      .watch(communityRepositoryProvider)
      .watchBlockedUserIds()
      .handleError((_) {});
});

final restrictedUserIdsProvider = StreamProvider<List<String>>((ref) {
  return ref
      .watch(communityRepositoryProvider)
      .watchRestrictedUserIds()
      .handleError((_) {});
});
