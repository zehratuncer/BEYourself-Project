import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:be_yourself/features/media/services/media_storage_service.dart';
import 'package:be_yourself/shared/widgets/app_media_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaStorageService Tests', () {
    test('MediaStorageService singleton instance check', () {
      final s1 = MediaStorageService.instance;
      final s2 = MediaStorageService.instance;
      expect(identical(s1, s2), isTrue);
    });

    test('resolveLocalFileSync returns valid File for any path', () {
      final file = MediaStorageService.instance.resolveLocalFileSync('test_image.jpg');
      expect(file, isA<File>());
      expect(file.path, contains('test_image.jpg'));
    });

    test('resolveLocalFile handles null and empty path gracefully', () async {
      final nullRes = await MediaStorageService.instance.resolveLocalFile(null);
      expect(nullRes, isNull);

      final emptyRes = await MediaStorageService.instance.resolveLocalFile('   ');
      expect(emptyRes, isNull);
    });
  });

  group('AppMediaImage Widget Tests', () {
    testWidgets('AppMediaImage renders placeholder on empty path', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppMediaImage(imagePath: ''),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.text('Görsel Yüklenemedi'), findsOneWidget);
    });
  });
}
