import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class InstagramDownloaderService {
  InstagramDownloaderService._();
  static final InstagramDownloaderService instance =
      InstagramDownloaderService._();

  static final RegExp _instagramUrlRegex = RegExp(
    r'(https?:\/\/)?(www\.)?(instagram\.com|instagr\.am)\/(reel|reels|p)\/([a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );

  /// Validates if the given string is a valid Instagram Reel or Post URL.
  bool isValidInstagramUrl(String url) {
    return _instagramUrlRegex.hasMatch(url.trim());
  }

  /// Extracts the clean shortcode from an Instagram URL.
  String? extractShortcode(String url) {
    final match = _instagramUrlRegex.firstMatch(url.trim());
    if (match != null && match.groupCount >= 5) {
      return match.group(5);
    }
    return null;
  }

  /// Resolves direct MP4 video URL from Instagram Reels link.
  Future<String?> resolveVideoUrl(String rawUrl) async {
    final shortcode = extractShortcode(rawUrl);
    if (shortcode == null) {
      throw const FormatException('Geçersiz Instagram Reels bağlantısı.');
    }

    final normalizedUrl = 'https://www.instagram.com/reel/$shortcode/';

    // Strategy 1: Cobalt API / Open Video Resolver
    try {
      final response = await http.post(
        Uri.parse('https://co.wuk.sh/api/json'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': normalizedUrl,
          'vQuality': '720',
          'filenamePattern': 'basic',
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['url'] != null && data['url'].toString().isNotEmpty) {
          return data['url'] as String;
        }
      }
    } catch (e) {
      debugPrint('Strategy 1 (Cobalt) error: $e');
    }

    // Strategy 2: Instagram Embed Page HTML Extraction
    try {
      final embedUrl = 'https://www.instagram.com/p/$shortcode/embed/captioned/';
      final response = await http.get(
        Uri.parse(embedUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final html = response.body;

        // Try extracting video src directly from HTML
        final videoSrcMatch = RegExp(r'<video[^>]+src="([^">]+)"').firstMatch(html);
        if (videoSrcMatch != null && videoSrcMatch.group(1) != null) {
          final extractedUrl = videoSrcMatch.group(1)!.replaceAll('&amp;', '&');
          return extractedUrl;
        }

        // Try regex match for video_url in embedded JSON payload
        final jsonVideoUrlMatch = RegExp(r'"video_url":"([^"]+)"').firstMatch(html);
        if (jsonVideoUrlMatch != null && jsonVideoUrlMatch.group(1) != null) {
          var cleanUrl = jsonVideoUrlMatch.group(1)!;
          cleanUrl = cleanUrl.replaceAll(r'\u0026', '&').replaceAll(r'\/', '/');
          return cleanUrl;
        }
      }
    } catch (e) {
      debugPrint('Strategy 2 (Embed page) error: $e');
    }

    // Strategy 3: Instagram GraphQL / Open Graph HTML Meta Scraper
    try {
      final response = await http.get(
        Uri.parse(normalizedUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final html = response.body;
        final ogVideoMatch = RegExp(
          r'<meta\s+property="og:video(:secure_url)?"\s+content="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(html);

        if (ogVideoMatch != null && ogVideoMatch.group(2) != null) {
          return ogVideoMatch.group(2)!.replaceAll('&amp;', '&');
        }
      }
    } catch (e) {
      debugPrint('Strategy 3 (OpenGraph) error: $e');
    }

    return null;
  }

  /// Downloads the Instagram Reel video file and saves it to local app storage.
  /// Returns the absolute local file path (`.mp4`).
  Future<String> downloadReel({
    required String instagramUrl,
    void Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.1, 'Bağlantı doğrulanıyor...');

    if (!isValidInstagramUrl(instagramUrl)) {
      throw const FormatException('Lütfen geçerli bir Instagram Reels linki giriniz.');
    }

    final shortcode = extractShortcode(instagramUrl);
    onProgress?.call(0.3, 'Video adresi çözümleniyor...');

    final directVideoUrl = await resolveVideoUrl(instagramUrl);
    if (directVideoUrl == null || directVideoUrl.isEmpty) {
      throw const HttpException(
        'Video indirilemedi. Gönderi gizli bir hesaba ait olabilir veya Instagram erişimi kısıtlamış olabilir.',
      );
    }

    onProgress?.call(0.5, 'Video indiriliyor...');

    final appDocDir = await getApplicationDocumentsDirectory();
    final reelsDir = Directory('${appDocDir.path}/reels');
    if (!await reelsDir.exists()) {
      await reelsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${reelsDir.path}/reel_${shortcode ?? "video"}_$timestamp.mp4';
    final file = File(filePath);

    final request = http.Request('GET', Uri.parse(directVideoUrl));
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = 0.5 + (receivedBytes / totalBytes) * 0.5;
          final percentage = ((receivedBytes / totalBytes) * 100).toInt();
          onProgress?.call(progress.clamp(0.5, 0.99), 'İndiriliyor... %$percentage');
        }
      }

      await sink.flush();
      await sink.close();

      onProgress?.call(1.0, 'İndirme tamamlandı! ✨');
      return file.path;
    } finally {
      client.close();
    }
  }
}
