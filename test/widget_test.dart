import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mvhs_football/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MvhsFootballApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the app launches and shows the login screen
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
