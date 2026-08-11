import 'package:flutter_test/flutter_test.dart';
import 'package:be_yourself/features/media/services/instagram_downloader_service.dart';

void main() {
  group('InstagramDownloaderService Tests', () {
    late InstagramDownloaderService service;

    setUp(() {
      service = InstagramDownloaderService.instance;
    });

    test('InstagramDownloaderService is a singleton', () {
      expect(InstagramDownloaderService.instance, equals(service));
    });

    test('Validates various Instagram Reels and Post URLs correctly', () {
      expect(
        service.isValidInstagramUrl('https://www.instagram.com/reel/C8x123abc/'),
        isTrue,
      );
      expect(
        service.isValidInstagramUrl('https://instagram.com/reel/C8x123abc?igsh=abc1234'),
        isTrue,
      );
      expect(
        service.isValidInstagramUrl('https://www.instagram.com/reels/C8x123abc/'),
        isTrue,
      );
      expect(
        service.isValidInstagramUrl('https://www.instagram.com/p/C8x123abc/'),
        isTrue,
      );
      expect(
        service.isValidInstagramUrl('http://instagr.am/reel/C8x123abc/'),
        isTrue,
      );
      expect(
        service.isValidInstagramUrl('instagram.com/reel/C8x123abc/'),
        isTrue,
      );
    });

    test('Rejects invalid non-reel Instagram or foreign URLs', () {
      expect(service.isValidInstagramUrl('https://www.google.com'), isFalse);
      expect(service.isValidInstagramUrl('https://www.instagram.com/username/'), isFalse);
      expect(service.isValidInstagramUrl('https://twitter.com/user/status/123'), isFalse);
      expect(service.isValidInstagramUrl(''), isFalse);
      expect(service.isValidInstagramUrl('not a url'), isFalse);
    });

    test('extractShortcode extracts exact code from URL', () {
      expect(
        service.extractShortcode('https://www.instagram.com/reel/C8x_Abc-123/?igsh=123'),
        'C8x_Abc-123',
      );
      expect(
        service.extractShortcode('https://instagram.com/p/D_testCode/'),
        'D_testCode',
      );
      expect(
        service.extractShortcode('https://invalid.com/video'),
        isNull,
      );
    });

    test('downloadReel throws FormatException on invalid URL', () async {
      expect(
        () => service.downloadReel(instagramUrl: 'invalid_url_string'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
