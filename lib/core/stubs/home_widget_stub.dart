// Stub for home_widget on web — provides no-op implementations
// so the import in main.dart compiles on web without crashing.

class HomeWidget {
  static Stream<Uri?> get widgetClicked => const Stream.empty();
  static Future<void> saveWidgetData<T>(String id, T data) async {}
  static Future<T?> getWidgetData<T>(String id, {T? defaultValue}) async => defaultValue;
  static Future<bool?> updateWidget({String? name, String? androidName, String? qualifiedAndroidName, String? iOSName}) async => false;
}
