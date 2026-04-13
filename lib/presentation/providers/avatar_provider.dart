import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'faculty_provider.dart';

final _picker = ImagePicker();

class AvatarNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AvatarNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Pick an image from gallery and save it as base64 on the faculty record.
  Future<void> pickAndUpload(String facultyId) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (file == null) return; // user cancelled

      state = const AsyncValue.loading();
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      final repo = _ref.read(facultyRepositoryProvider);
      final faculty = await repo.getFacultyById(facultyId);
      if (faculty == null) {
        state = AsyncValue.error('Faculty not found', StackTrace.current);
        return;
      }

      await repo.updateFaculty(faculty.copyWith(avatarUrl: base64Str));
      // Invalidate so all watchers refresh
      _ref.invalidate(facultyByIdProvider);
      _ref.invalidate(facultyListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove avatar — revert to initials.
  Future<void> removeAvatar(String facultyId) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(facultyRepositoryProvider);
      final faculty = await repo.getFacultyById(facultyId);
      if (faculty == null) return;
      await repo.updateFaculty(faculty.copyWith(avatarUrl: ''));
      _ref.invalidate(facultyByIdProvider);
      _ref.invalidate(facultyListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final avatarNotifierProvider =
    StateNotifierProvider<AvatarNotifier, AsyncValue<void>>((ref) {
  return AvatarNotifier(ref);
});
