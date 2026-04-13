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
  return repo.watch().map((msgs) {
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
}

final communityNotifierProvider =
    StateNotifierProvider<CommunityNotifier, AsyncValue<void>>((ref) {
  return CommunityNotifier(ref.watch(communityRepositoryProvider));
});
