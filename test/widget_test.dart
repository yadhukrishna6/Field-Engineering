import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_engineering/main.dart';

void main() {
  testWidgets('Field engineering root app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FieldEngineeringApp(),
      ),
    );
    expect(find.byType(FieldEngineeringApp), findsOneWidget);
  });
}
