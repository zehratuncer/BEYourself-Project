import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class InstagramMediaItem {
  const InstagramMediaItem({
    required this.url,
    this.isVideo = false,
  });

  final String url;
  final bool isVideo;
}

class InstagramResolvedData {
  const InstagramResolvedData({
    required this.mediaItems,
    this.caption,
    this.authorUsername,
    this.authorFullName,
  });

  final List<InstagramMediaItem> mediaItems;
  final String? caption;
  final String? authorUsername;
  final String? authorFullName;

  String? get videoUrl => mediaItems.isNotEmpty && mediaItems.first.isVideo
      ? mediaItems.first.url
      : (mediaItems.isNotEmpty ? mediaItems.first.url : null);
}

class InstagramDownloadResult {
  const InstagramDownloadResult({
    required this.filePaths,
    this.caption,
    this.authorUsername,
    this.authorFullName,
  });

  final List<String> filePaths;
  final String? caption;
  final String? authorUsername;
  final String? authorFullName;

  String get filePath => filePaths.isNotEmpty ? filePaths.first : '';
}

typedef InstagramReelResult = InstagramDownloadResult;
typedef ReelResolvedData = InstagramResolvedData;

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

  /// Resolves media stream URLs, caption and author from Instagram link (Post/Reels/Carousel).
  Future<InstagramResolvedData?> resolveInstagramData(String rawUrl) async {
    final shortcode = extractShortcode(rawUrl);
    if (shortcode == null) {
      throw const FormatException('Geçersiz Instagram bağlantısı.');
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
          final List<InstagramMediaItem> items = [];

          // Check for carousel sidecar (multiple images/videos)
          if (media['edge_sidecar_to_children'] != null) {
            final edges =
                media['edge_sidecar_to_children']['edges'] as List<dynamic>?;
            if (edges != null && edges.isNotEmpty) {
              for (final edge in edges) {
                final node = edge['node'] as Map<String, dynamic>?;
                if (node != null) {
                  if (node['is_video'] == true && node['video_url'] != null) {
                    items.add(InstagramMediaItem(
                      url: node['video_url'] as String,
                      isVideo: true,
                    ));
                  } else if (node['display_url'] != null) {
                    items.add(InstagramMediaItem(
                      url: node['display_url'] as String,
                      isVideo: false,
                    ));
                  } else if (node['display_resources'] != null) {
                    final res = node['display_resources'] as List<dynamic>?;
                    if (res != null && res.isNotEmpty) {
                      items.add(InstagramMediaItem(
                        url: res.last['src'] as String,
                        isVideo: false,
                      ));
                    }
                  }
                }
              }
            }
          }

          // If not a sidecar or sidecar had no items, check single video or single photo
          if (items.isEmpty) {
            if (media['is_video'] == true && media['video_url'] != null) {
              items.add(InstagramMediaItem(
                url: media['video_url'] as String,
                isVideo: true,
              ));
            } else if (media['display_url'] != null) {
              items.add(InstagramMediaItem(
                url: media['display_url'] as String,
                isVideo: false,
              ));
            } else if (media['video_url'] != null) {
              items.add(InstagramMediaItem(
                url: media['video_url'] as String,
                isVideo: true,
              ));
            }
          }

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

          if (items.isNotEmpty) {
            return InstagramResolvedData(
              mediaItems: items,
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
        final List<InstagramMediaItem> embedItems = [];

        final videoSrcMatch =
            RegExp(r'<video[^>]+src="([^">]+)"').firstMatch(html);
        if (videoSrcMatch != null && videoSrcMatch.group(1) != null) {
          final extractedUrl =
              videoSrcMatch.group(1)!.replaceAll('&amp;', '&');
          embedItems.add(InstagramMediaItem(url: extractedUrl, isVideo: true));
        }

        final imgSrcMatches = RegExp(
                r'<img[^>]+class="EmbeddedMediaImage"[^>]+src="([^">]+)"')
            .allMatches(html);
        for (final m in imgSrcMatches) {
          if (m.group(1) != null) {
            embedItems.add(InstagramMediaItem(
              url: m.group(1)!.replaceAll('&amp;', '&'),
              isVideo: false,
            ));
          }
        }

        if (embedItems.isNotEmpty) {
          return InstagramResolvedData(mediaItems: embedItems);
        }
      }
    } catch (e) {
      debugPrint('Strategy 2 (Embed page) error: $e');
    }

    // Strategy 3: OpenGraph HTML Meta Tag Scraper
    try {
      final normalizedUrl = 'https://www.instagram.com/p/$shortcode/';
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
          return InstagramResolvedData(
            mediaItems: [InstagramMediaItem(url: directUrl, isVideo: true)],
          );
        }

        final ogImageMatch = RegExp(
          r'<meta\s+property="og:image(:secure_url)?"\s+content="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(html);

        if (ogImageMatch != null && ogImageMatch.group(2) != null) {
          final directUrl = ogImageMatch.group(2)!.replaceAll('&amp;', '&');
          return InstagramResolvedData(
            mediaItems: [InstagramMediaItem(url: directUrl, isVideo: false)],
          );
        }
      }
    } catch (e) {
      debugPrint('Strategy 3 (OpenGraph) error: $e');
    }

    return null;
  }

  /// Backward compatibility alias for resolveReelData
  Future<InstagramResolvedData?> resolveReelData(String rawUrl) async {
    return resolveInstagramData(rawUrl);
  }

  /// Downloads Instagram Post/Reel media files (up to 10 items) and saves them locally.
  Future<InstagramDownloadResult> downloadPost({
    required String instagramUrl,
    void Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.1, 'Bağlantı doğrulanıyor...');

    if (!isValidInstagramUrl(instagramUrl)) {
      throw const FormatException(
          'Lütfen geçerli bir Instagram linki giriniz.');
    }

    final shortcode = extractShortcode(instagramUrl);
    onProgress?.call(0.25, 'Gönderi bilgileri çekiliyor...');

    final resolved = await resolveInstagramData(instagramUrl);
    if (resolved == null || resolved.mediaItems.isEmpty) {
      throw const HttpException(
        'Medya indirilemedi. Gönderi gizli bir hesaba ait olabilir veya Instagram erişimi kısıtlamış olabilir.',
      );
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDocDir.path}/instagram_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final List<String> downloadedFilePaths = [];
    final totalItems = resolved.mediaItems.length;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < totalItems; i++) {
      final item = resolved.mediaItems[i];
      final ext = item.isVideo ? 'mp4' : 'jpg';
      final filePath =
          '${mediaDir.path}/ig_${shortcode ?? "media"}_${timestamp}_$i.$ext';
      final file = File(filePath);

      final currentItemNum = i + 1;
      onProgress?.call(
        0.3 + (i / totalItems) * 0.65,
        totalItems > 1
            ? 'İndiriliyor... ($currentItemNum / $totalItems)'
            : 'İndiriliyor...',
      );

      final response = await http.get(
        Uri.parse(item.url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        downloadedFilePaths.add(file.path);
      }
    }

    if (downloadedFilePaths.isEmpty) {
      throw const HttpException('Medya dosyaları kaydedilemedi.');
    }

    onProgress?.call(1.0, 'İndirme tamamlandı! ✨');

    return InstagramDownloadResult(
      filePaths: downloadedFilePaths,
      caption: resolved.caption,
      authorUsername: resolved.authorUsername,
      authorFullName: resolved.authorFullName,
    );
  }

  /// Backward compatibility wrapper for downloadReel
  Future<InstagramDownloadResult> downloadReel({
    required String instagramUrl,
    void Function(double progress, String status)? onProgress,
  }) async {
    return downloadPost(instagramUrl: instagramUrl, onProgress: onProgress);
  }
}
