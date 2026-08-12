import 'package:flutter_test/flutter_test.dart';
import 'package:be_yourself/features/home_widget/services/home_widget_service.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeWidgetService Tests', () {
    test('HomeWidgetService singleton instance check', () {
      final instance1 = HomeWidgetService.instance;
      final instance2 = HomeWidgetService.instance;
      expect(instance1, equals(instance2));
    });

    test('HomeWidgetService constants are correctly configured', () {
      expect(HomeWidgetService.appGroupId, 'group.com.example.be_yourself');
      expect(HomeWidgetService.androidWidgetName, 'QuoteWidgetProvider');
      expect(HomeWidgetService.iOSWidgetName, 'BeYourselfWidget');
    });

    test('updateQuoteWidget runs safely with sample Quote', () async {
      final sampleQuote = Quote(
        id: 'quote_test_1',
        text: 'Kendine inan.',
        author: 'Zehra',
        categoryName: 'Motivasyon',
        createdAt: DateTime.now(),
      );

      // Should complete without throwing uncaught errors
      await expectLater(
        HomeWidgetService.instance.updateQuoteWidget(sampleQuote),
        completes,
      );
    });

    test('defaultFallbackQuote has valid non-empty fields', () {
      final fallback = HomeWidgetService.defaultFallbackQuote;
      expect(fallback.id, 'default_fallback');
      expect(fallback.text.isNotEmpty, true);
      expect(fallback.author.isNotEmpty, true);
    });

    test('updateWidgetWithFallback runs safely', () async {
      await expectLater(
        HomeWidgetService.instance.updateWidgetWithFallback(),
        completes,
      );
    });

    test('handleWidgetUri parses queryParameters safely', () {
      final uri = Uri.parse('beyourself://quote?id=test_quote_42');
      expect(uri.queryParameters['id'], 'test_quote_42');

      // Should not throw even if navigator is not mounted in unit test environment
      expect(() => HomeWidgetService.instance.handleWidgetUri(uri), returnsNormally);
    });
  });
}
