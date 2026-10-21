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

    test('downloadReel and downloadPost throw FormatException on invalid URL', () async {
      expect(
        () => service.downloadReel(instagramUrl: 'invalid_url_string'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => service.downloadPost(instagramUrl: 'invalid_url_string'),
        throwsA(isA<FormatException>()),
      );
    });

    test('InstagramDownloadResult model has valid getters', () {
      const result = InstagramDownloadResult(
        filePaths: ['/path/to/img1.jpg', '/path/to/img2.jpg'],
        caption: 'Harika bir gün! ✨ #ilham',
        authorUsername: 'zehratuncer',
        authorFullName: 'Zehra Tuncer',
      );

      expect(result.filePaths.length, 2);
      expect(result.filePath, '/path/to/img1.jpg');
      expect(result.caption, contains('Harika bir gün'));
      expect(result.authorUsername, 'zehratuncer');
    });

    test('InstagramResolvedData and InstagramMediaItem handle multi-photo carousel', () {
      final items = List.generate(
        11,
        (index) => InstagramMediaItem(
          url: 'https://scontent.cdninstagram.com/v/photo_$index.jpg?_nc_cat=1&amp;oh=abc',
          isVideo: false,
        ),
      );

      final resolved = InstagramResolvedData(
        mediaItems: items,
        caption: '11 Fotoğraflı Carousel Post',
        authorUsername: 'zehratuncer',
      );

      expect(resolved.mediaItems.length, 11);
      expect(resolved.videoUrl, contains('photo_0.jpg'));
      expect(resolved.caption, '11 Fotoğraflı Carousel Post');
    });

    test('InstagramResolvedData distinguishes between Reel video and photo', () {
      final reelItems = [
        const InstagramMediaItem(
          url: 'https://scontent.cdninstagram.com/o1/v/t16/f1/m86/reel.mp4?_nc_cat=1',
          isVideo: true,
        ),
      ];

      final reelResolved = InstagramResolvedData(
        mediaItems: reelItems,
        caption: 'İlham verici bir reels videosu #motivasyon',
        authorUsername: 'motivasyon_sozleri',
      );

      expect(reelResolved.mediaItems.first.isVideo, isTrue);
      expect(reelResolved.videoUrl, contains('.mp4'));
    });
  });
}
