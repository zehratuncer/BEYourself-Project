import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class InstagramReelResult {
  const InstagramReelResult({
    required this.filePath,
    this.caption,
    this.authorUsername,
    this.authorFullName,
  });

  final String filePath;
  final String? caption;
  final String? authorUsername;
  final String? authorFullName;
}

class _ReelResolvedData {
  const _ReelResolvedData({
    required this.videoUrl,
    this.caption,
    this.authorUsername,
    this.authorFullName,
  });

  final String videoUrl;
  final String? caption;
  final String? authorUsername;
  final String? authorFullName;
}

class InstagramDownloaderService {
  InstagramDownloaderService._();
  static final InstagramDownloaderService instance =
      InstagramDownloaderService._();

  static final RegExp _instagramUrlRegex = RegExp(
    r'(https?:\/\/)?(www\.)?(instagram\.com|instagr\.am)\/(reel|reels|p|share\/reel|share\/p|tv)\/([a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );

  /// Validates if the given string is a valid Instagram Reel or Post URL.
  bool isValidInstagramUrl(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return false;
    return extractShortcode(clean) != null;
  }

  /// Extracts the clean shortcode from an Instagram URL.
  String? extractShortcode(String url) {
    final clean = url.trim();
    final uri = Uri.tryParse(clean);

    if (uri != null) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i].toLowerCase();
        if ((seg == 'reel' || seg == 'reels' || seg == 'p' || seg == 'tv') &&
            i + 1 < segments.length) {
          return segments[i + 1];
        }
      }
    }

    final match = _instagramUrlRegex.firstMatch(clean);
    if (match != null && match.groupCount >= 5) {
      return match.group(5);
    }
    return null;
  }

  /// Resolves video stream URL, caption and author from Instagram Reels link.
  Future<_ReelResolvedData?> resolveReelData(String rawUrl) async {
    final shortcode = extractShortcode(rawUrl);
    if (shortcode == null) {
      throw const FormatException('Geçersiz Instagram Reels bağlantısı.');
    }

    // Strategy 1: Official Instagram GraphQL Query (doc_id=10015901848480474)
    try {
      final uri = Uri.parse(
        'https://www.instagram.com/graphql/query/?doc_id=10015901848480474&variables=%7B%22shortcode%22:%22$shortcode%22%7D',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
          'X-IG-App-ID': '936619743392459',
          'Accept': '*/*',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final media = data['data']?['xdt_shortcode_media'];
        if (media != null) {
          String? directUrl;
          if (media['video_url'] != null &&
              media['video_url'].toString().isNotEmpty) {
            directUrl = media['video_url'] as String;
          } else if (media['edge_sidecar_to_children'] != null) {
            final edges =
                media['edge_sidecar_to_children']['edges'] as List<dynamic>?;
            if (edges != null) {
              for (final edge in edges) {
                final node = edge['node'] as Map<String, dynamic>?;
                if (node != null &&
                    node['is_video'] == true &&
                    node['video_url'] != null) {
                  directUrl = node['video_url'] as String;
                  break;
                }
              }
            }
          }

          if (directUrl != null && directUrl.isNotEmpty) {
            // Extract caption
            String? caption;
            if (media['edge_media_to_caption'] != null) {
              final captionEdges = media['edge_media_to_caption']['edges']
                  as List<dynamic>?;
              if (captionEdges != null && captionEdges.isNotEmpty) {
                caption = captionEdges.first['node']?['text'] as String?;
              }
            }

            // Extract author info
            String? authorUsername;
            String? authorFullName;
            if (media['owner'] != null) {
              authorUsername = media['owner']['username'] as String?;
              authorFullName = media['owner']['full_name'] as String?;
            }

            return _ReelResolvedData(
              videoUrl: directUrl,
              caption: caption,
              authorUsername: authorUsername,
              authorFullName: authorFullName,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Strategy 1 (GraphQL doc_id) error: $e');
    }

    // Strategy 2: Instagram Embed Page HTML Extraction
    try {
      final embedUrl =
          'https://www.instagram.com/p/$shortcode/embed/captioned/';
      final response = await http.get(
        Uri.parse(embedUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final html = response.body;

        final videoSrcMatch =
            RegExp(r'<video[^>]+src="([^">]+)"').firstMatch(html);
        if (videoSrcMatch != null && videoSrcMatch.group(1) != null) {
          final extractedUrl =
              videoSrcMatch.group(1)!.replaceAll('&amp;', '&');
          return _ReelResolvedData(videoUrl: extractedUrl);
        }

        final jsonVideoUrlMatch =
            RegExp(r'"video_url":"([^"]+)"').firstMatch(html);
        if (jsonVideoUrlMatch != null && jsonVideoUrlMatch.group(1) != null) {
          var cleanUrl = jsonVideoUrlMatch.group(1)!;
          cleanUrl =
              cleanUrl.replaceAll(r'\u0026', '&').replaceAll(r'\/', '/');
          return _ReelResolvedData(videoUrl: cleanUrl);
        }
      }
    } catch (e) {
      debugPrint('Strategy 2 (Embed page) error: $e');
    }

    // Strategy 3: OpenGraph HTML Meta Tag Scraper
    try {
      final normalizedUrl = 'https://www.instagram.com/reel/$shortcode/';
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
          final directUrl = ogVideoMatch.group(2)!.replaceAll('&amp;', '&');
          return _ReelResolvedData(videoUrl: directUrl);
        }
      }
    } catch (e) {
      debugPrint('Strategy 3 (OpenGraph) error: $e');
    }

    return null;
  }

  /// Downloads the Instagram Reel video file and saves it to local app storage.
  /// Returns [InstagramReelResult] containing the local file path, caption and author.
  Future<InstagramReelResult> downloadReel({
    required String instagramUrl,
    void Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.1, 'Bağlantı doğrulanıyor...');

    if (!isValidInstagramUrl(instagramUrl)) {
      throw const FormatException(
          'Lütfen geçerli bir Instagram Reels linki giriniz.');
    }

    final shortcode = extractShortcode(instagramUrl);
    onProgress?.call(0.3, 'Video bilgileri çekiliyor...');

    final resolved = await resolveReelData(instagramUrl);
    if (resolved == null || resolved.videoUrl.isEmpty) {
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
    final filePath =
        '${reelsDir.path}/reel_${shortcode ?? "video"}_$timestamp.mp4';
    final file = File(filePath);

    final request = http.Request('GET', Uri.parse(resolved.videoUrl));
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
          onProgress?.call(
              progress.clamp(0.5, 0.99), 'İndiriliyor... %$percentage');
        }
      }

      await sink.flush();
      await sink.close();

      onProgress?.call(1.0, 'İndirme tamamlandı! ✨');
      return InstagramReelResult(
        filePath: file.path,
        caption: resolved.caption,
        authorUsername: resolved.authorUsername,
        authorFullName: resolved.authorFullName,
      );
    } finally {
      client.close();
    }
  }
}
