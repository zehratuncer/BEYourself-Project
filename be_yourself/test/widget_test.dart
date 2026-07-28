import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quote_reminder/core/constants/app_strings.dart';
import 'package:quote_reminder/main.dart';

void main() {
  testWidgets('WelcomePage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.welcomeSubtitle), findsOneWidget);

    // Advance timer past splash duration
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
