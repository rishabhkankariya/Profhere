import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profhere/app.dart';

void main() {
  testWidgets('renders app bootstrap', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProfHereApp()));

    expect(find.byType(ProfHereApp), findsOneWidget);
  });
}
