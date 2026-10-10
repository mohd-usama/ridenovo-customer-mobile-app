import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridonova/main.dart';

void main() {
  testWidgets('App loads splash screen test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RidonovaApp(),
      ),
    );

    expect(find.text('RIDONOVA'), findsOneWidget);

    // Let the splash timer finish and transition
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
