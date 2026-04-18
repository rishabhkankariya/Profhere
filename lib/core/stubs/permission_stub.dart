// Stub for permission_handler on web
// Provides no-op classes so the code compiles without crashing on web.

class Permission {
  static final camera = _PermissionRequest();
  static final notification = _PermissionRequest();
}

class _PermissionRequest {
  Future<PermissionStatus> request() async => PermissionStatus.denied;
  Future<bool> get isGranted async => false;
}

class PermissionStatus {
  static const granted = PermissionStatus._('granted');
  static const denied = PermissionStatus._('denied');
  final String _value;
  const PermissionStatus._(this._value);
  bool get isGranted => _value == 'granted';
}
