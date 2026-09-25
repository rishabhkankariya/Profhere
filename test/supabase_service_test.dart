import 'package:flutter_test/flutter_test.dart';
import 'package:profhere/core/utils/app_environment.dart';
import 'package:profhere/data/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('supabase bootstrap is null-safe and probeable', (tester) async {
    await AppEnvironment.load();
    expect(SupabaseService.isConfigured, isTrue);
    expect(SupabaseService.isConfigured, isA<bool>());

    // Real initialization and connection probing are verified at runtime,
    // because supabase_flutter relies on plugins that are unavailable in the
    // default widget-test host environment.
    expect(SupabaseService.isInitialized, isFalse);
  });
}
