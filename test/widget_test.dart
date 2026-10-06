import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_engineering/main.dart';
import 'package:field_engineering/features/markup/presentation/screens/home_screen.dart';

void main() {
  testWidgets('Drawing markup root app launches directly into HomeScreen with Desert theme hero card', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DrawingMarkupApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(DrawingMarkupApp), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Drawing markup'), findsOneWidget);
    expect(find.text('Drawings'), findsOneWidget);
  });
}
