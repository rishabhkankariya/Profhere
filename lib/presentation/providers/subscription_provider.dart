import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/hive_service.dart';
import '../../core/services/audio_service.dart';
import 'auth_provider.dart';

/// Persists subscribed faculty IDs per user in the settings box.
/// Key format: subs_{userId}
class SubscriptionNotifier extends StateNotifier<Set<String>> {
  final String _userId;

  SubscriptionNotifier(this._userId) : super(_load(_userId));

  static Set<String> _load(String userId) {
    if (userId.isEmpty) return {};
    final raw = HiveService.settings.get('subs_$userId');
    if (raw == null) return {};
    return (raw as List).whereType<String>().toSet();
  }

  Future<void> toggle(String facultyId) async {
    final next = Set<String>.from(state);
    final wasSubscribed = next.contains(facultyId);
    if (wasSubscribed) {
      next.remove(facultyId);
      AudioService.play(AppSound.unsubscribe);
    } else {
      next.add(facultyId);
      AudioService.play(AppSound.subscribe);
    }
    state = next;
    await HiveService.settings.put('subs_$_userId', next.toList());
  }

  bool isSubscribed(String facultyId) => state.contains(facultyId);
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, Set<String>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id ?? '';
  return SubscriptionNotifier(userId);
});
