import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/local/hive_service.dart';
import 'auth_provider.dart';

enum FacultySort { nameAsc, statusFirst, subscribed }

/// How the student appears in Community Chat
enum CommunityMode {
  public,    // real name + initials avatar
  private,   // real name + uploaded photo
  anonymous, // "Anonymous" + people icon, no name
}

class UserPrefs {
  final bool notificationsEnabled;
  final FacultySort sort;
  final CommunityMode communityMode;
  final String? avatarBase64; // student's own uploaded photo

  const UserPrefs({
    this.notificationsEnabled = true,
    this.sort = FacultySort.subscribed,
    this.communityMode = CommunityMode.public,
    this.avatarBase64,
  });

  UserPrefs copyWith({
    bool? notificationsEnabled,
    FacultySort? sort,
    CommunityMode? communityMode,
    String? avatarBase64,
  }) {
    return UserPrefs(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      sort: sort ?? this.sort,
      communityMode: communityMode ?? this.communityMode,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
    );
  }

  UserPrefs withNoAvatar() => UserPrefs(
    notificationsEnabled: notificationsEnabled,
    sort: sort,
    communityMode: communityMode,
    avatarBase64: null,
  );
}

class UserPrefsNotifier extends StateNotifier<UserPrefs> {
  final String _userId;
  static final _picker = ImagePicker();

  UserPrefsNotifier(this._userId) : super(_load(_userId));

  static UserPrefs _load(String userId) {
    if (userId.isEmpty) return const UserPrefs();
    final raw = HiveService.settings.get('prefs_$userId');
    if (raw == null) return const UserPrefs();
    return UserPrefs(
      notificationsEnabled: raw['notifications'] as bool? ?? true,
      sort: FacultySort.values[raw['sort'] as int? ?? FacultySort.subscribed.index],
      communityMode: CommunityMode.values[raw['communityMode'] as int? ?? 0],
      avatarBase64: raw['avatarBase64'] as String?,
    );
  }

  Future<void> _save() async {
    await HiveService.settings.put('prefs_$_userId', {
      'notifications': state.notificationsEnabled,
      'sort': state.sort.index,
      'communityMode': state.communityMode.index,
      'avatarBase64': state.avatarBase64,
    });
  }

  Future<void> toggleNotifications() async {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
    await _save();
  }

  Future<void> setSort(FacultySort sort) async {
    state = state.copyWith(sort: sort);
    await _save();
  }

  Future<void> setCommunityMode(CommunityMode mode) async {
    state = state.copyWith(communityMode: mode);
    await _save();
  }

  Future<bool> pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300, maxHeight: 300, imageQuality: 75,
    );
    if (file == null) return false;
    final bytes = await file.readAsBytes();
    state = state.copyWith(avatarBase64: base64Encode(bytes));
    await _save();
    return true;
  }

  Future<void> removeAvatar() async {
    state = state.withNoAvatar();
    await _save();
  }
}

final userPrefsProvider =
    StateNotifierProvider<UserPrefsNotifier, UserPrefs>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id ?? '';
  return UserPrefsNotifier(userId);
});
