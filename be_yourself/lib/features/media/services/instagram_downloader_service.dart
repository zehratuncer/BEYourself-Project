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
    r'(https?:\/\/)?(www\.)?(instagram\.com|instagr\.am)\/(reel|reels|p|tv|share\/reel|share\/p|share)\/([a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );

  /// Validates if the given string is a valid Instagram Reel or Post URL.
  bool isValidInstagramUrl(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return false;
    if (!clean.contains('instagram.com') && !clean.contains('instagr.am')) {
      return false;
    }
    return extractShortcode(clean) != null;
  }

  /// Extracts the clean shortcode from an Instagram URL.
  String? extractShortcode(String url) {
    var clean = url.trim();
    if (clean.isEmpty) return null;

    // Remove query params if direct extraction
    final uri = Uri.tryParse(clean);
    if (uri != null) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i].toLowerCase();
        if ((seg == 'reel' || seg == 'reels' || seg == 'p' || seg == 'tv') &&
            i + 1 < segments.length) {
          return segments[i + 1];
        }
        if (seg == 'share' && i + 1 < segments.length) {
          final nextSeg = segments[i + 1].toLowerCase();
          if ((nextSeg == 'reel' || nextSeg == 'p') && i + 2 < segments.length) {
            return segments[i + 2];
          }
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

  /// Follows any shortlink redirects (e.g., share links) to retrieve the real shortcode.
  Future<String?> resolveCanonicalShortcode(String rawUrl) async {
    final directShortcode = extractShortcode(rawUrl);
    if (directShortcode != null &&
        directShortcode != 'share' &&
        directShortcode != 'reel' &&
        directShortcode != 'p') {
      return directShortcode;
    }

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(rawUrl))
        ..followRedirects = true
        ..maxRedirects = 5
        ..headers.addAll({
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        });
      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 6));
      final finalUrl = streamedResponse.headers['location'] ??
          streamedResponse.request?.url.toString();
      client.close();

      if (finalUrl != null) {
        return extractShortcode(finalUrl);
      }
    } catch (e) {
      debugPrint('Redirect resolution error: $e');
    }
    return directShortcode;
  }

  /// Performs HTTP GET with automatic CORS-proxy fallback on Web platforms.
  Future<http.Response> _fetch(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final defaultHeaders = headers ??
        {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'X-IG-App-ID': '936619743392459',
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': '*/*',
        };

    if (kIsWeb) {
      final target = uri.toString();
      final proxies = [
        'https://corsproxy.io/?url=${Uri.encodeComponent(target)}',
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(target)}',
        'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(target)}',
      ];

      for (final proxy in proxies) {
        try {
          final res = await http.get(Uri.parse(proxy)).timeout(timeout);
          if (res.statusCode == 200 && res.body.isNotEmpty) {
            return res;
          }
        } catch (_) {}
      }
    }

    return http.get(uri, headers: defaultHeaders).timeout(timeout);
  }

  /// Issues the POST request Instagram's current (2025+) GraphQL endpoint
  /// requires. Returns null if every attempt (direct call, or CORS proxies
  /// on Web) fails.
  Future<http.Response?> _postGraphQL(String docId, String shortcode) async {
    final variables = jsonEncode({'shortcode': shortcode});
    final body = {
      'doc_id': docId,
      'variables': variables,
      'lsd': 'AVqbxe3J_YA',
    };
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      'X-IG-App-ID': '936619743392459',
      'X-FB-LSD': 'AVqbxe3J_YA',
      'X-ASBD-ID': '129477',
      'Sec-Fetch-Site': 'same-origin',
    };
    const target = 'https://www.instagram.com/api/graphql';

    if (!kIsWeb) {
      try {
        return await http
            .post(Uri.parse(target), headers: headers, body: body)
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('GraphQL POST (direct) error: $e');
        return null;
      }
    }

    // Web: direct calls are blocked by CORS, so relay through proxies that
    // forward method/body to the target instead of only supporting GET.
    final proxies = [
      'https://corsproxy.io/?url=${Uri.encodeComponent(target)}',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(target)}',
    ];
    for (final proxy in proxies) {
      try {
        final res = await http
            .post(Uri.parse(proxy), headers: headers, body: body)
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          return res;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Resolves media stream URLs, caption, and author info across multiple strategies.
  Future<InstagramResolvedData?> resolveInstagramData(String rawUrl) async {
    final shortcode = await resolveCanonicalShortcode(rawUrl) ??
        extractShortcode(rawUrl);

    if (shortcode == null) {
      throw const FormatException('Geçersiz veya tanınmayan Instagram bağlantısı.');
    }

    // Strategy 0: High-speed Vercel Serverless Backend API (/api/instagram)
    try {
      final apiUrl = kIsWeb
          ? '/api/instagram?url=${Uri.encodeComponent(rawUrl)}'
          : 'https://be-yourself-project-orpin.vercel.app/api/instagram?url=${Uri.encodeComponent(rawUrl)}';

      final res = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['mediaItems'] != null) {
          final itemsList = data['mediaItems'] as List<dynamic>;
          final List<InstagramMediaItem> items = [];
          for (final it in itemsList) {
            if (it is Map<String, dynamic> && it['url'] != null) {
              items.add(InstagramMediaItem(
                url: it['url'] as String,
                isVideo: it['isVideo'] == true,
              ));
            }
          }

          if (items.isNotEmpty) {
            return InstagramResolvedData(
              mediaItems: items,
              caption: data['caption'] as String?,
              authorUsername: data['authorUsername'] as String?,
              authorFullName: data['authorFullName'] as String?,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Strategy 0 (Serverless API) error: $e');
    }

    // Strategy 1: Multi-DocID GraphQL queries via POST /api/graphql.
    // NOTE: the legacy GET /graphql/query/ endpoint used previously has been
    // retired by Instagram (now returns 404/redirect), which made this
    // strategy always fail and silently fall through to the embed/oEmbed
    // fallbacks below — those only ever return a single poster image, never
    // a playable video or the full carousel. This is the root cause of both
    // the "video becomes a screenshot" and "only first carousel photo" bugs.
    final docIds = [
      '10015901848480474',
      '8845758582119845',
      '7479768652077977',
      '25531498899829322',
    ];

    for (final docId in docIds) {
      try {
        final response = await _postGraphQL(docId, shortcode);
        if (response != null && response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final media = data['data']?['xdt_shortcode_media'] ??
              data['data']?['shortcode_media'];
          if (media != null) {
            final parsed = _parseGraphQLMedia(media);
            if (parsed != null && parsed.mediaItems.isNotEmpty) {
              return parsed;
            }
          }
        }
      } catch (e) {
        debugPrint('Strategy 1 (doc_id: $docId) error: $e');
      }
    }

    // Strategy 2: Instagram Web API JSON endpoints (__d=dis / __a=1)
    try {
      final webApiUrls = [
        'https://www.instagram.com/p/$shortcode/?__a=1&__d=dis',
        'https://www.instagram.com/reel/$shortcode/?__a=1&__d=1',
      ];

      for (final urlStr in webApiUrls) {
        final response = await _fetch(
          Uri.parse(urlStr),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
            'X-IG-App-ID': '936619743392459',
            'Accept': '*/*',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final media = data['graphql']?['shortcode_media'] ??
              (data['items'] != null && (data['items'] as List).isNotEmpty
                  ? (data['items'] as List).first
                  : null);
          if (media != null) {
            final parsed = _parseWebJsonMedia(media);
            if (parsed != null && parsed.mediaItems.isNotEmpty) {
              return parsed;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Strategy 2 (Web JSON) error: $e');
    }

    // Strategy 3: Embed page scraper with HTML and JS data parsing
    try {
      final embedUrl = 'https://www.instagram.com/p/$shortcode/embed/captioned/';
      final response = await _fetch(
        Uri.parse(embedUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (response.statusCode == 200) {
        final html = response.body;
        final List<InstagramMediaItem> embedItems = [];
        String? caption;
        String? authorUsername;

        // Prefer the real media graph embedded as JSON inside the page's
        // <script> blobs over the static <img>/<video> markup: the visible
        // markup only ever exposes a single poster frame for videos and only
        // the first slide for carousels, while the inline JSON (sidecar
        // edges / video_url) carries every item.
        try {
          final sidecarJson = _extractBalancedJson(html, 'edge_sidecar_to_children');
          if (sidecarJson != null) {
            final sidecar = jsonDecode(sidecarJson) as Map<String, dynamic>;
            final edges = sidecar['edges'] as List<dynamic>?;
            if (edges != null && edges.isNotEmpty) {
              for (final edge in edges) {
                final node = edge['node'] as Map<String, dynamic>?;
                if (node == null) continue;
                if (node['is_video'] == true && node['video_url'] != null) {
                  embedItems.add(InstagramMediaItem(
                    url: _sanitizeMediaUrl(node['video_url'] as String),
                    isVideo: true,
                  ));
                } else if (node['display_url'] != null) {
                  embedItems.add(InstagramMediaItem(
                    url: _sanitizeMediaUrl(node['display_url'] as String),
                    isVideo: false,
                  ));
                }
              }
            }
          }

          if (embedItems.isEmpty) {
            final videoUrlJsonMatch =
                RegExp(r'"video_url"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(html);
            if (videoUrlJsonMatch != null) {
              final decoded =
                  jsonDecode('"${videoUrlJsonMatch.group(1)}"') as String;
              embedItems.add(
                  InstagramMediaItem(url: _sanitizeMediaUrl(decoded), isVideo: true));
            }
          }
        } catch (e) {
          debugPrint('Strategy 3 deep JSON parse error: $e');
        }

        // Legacy fallback: static <video>/<img> markup (poster frame / first
        // slide only) — only used if the JSON-based extraction above found
        // nothing.
        if (embedItems.isEmpty) {
          final videoSrcMatch = RegExp(r'<video[^>]+src="([^">]+)"').firstMatch(html) ??
              RegExp(r'class="EmbeddedMediaVideo"[^>]+src="([^">]+)"').firstMatch(html);
          if (videoSrcMatch != null && videoSrcMatch.group(1) != null) {
            final extractedUrl = videoSrcMatch.group(1)!.replaceAll('&amp;', '&');
            embedItems.add(InstagramMediaItem(url: extractedUrl, isVideo: true));
          }
        }

        if (embedItems.isEmpty) {
          // Image extraction
          final imgSrcMatches = RegExp(
            r'<img[^>]+(?:class="EmbeddedMediaImage"|class="EmbeddedVideoPosterImage")[^>]+src="([^">]+)"',
          ).allMatches(html);
          for (final m in imgSrcMatches) {
            if (m.group(1) != null) {
              embedItems.add(InstagramMediaItem(
                url: m.group(1)!.replaceAll('&amp;', '&'),
                isVideo: false,
              ));
            }
          }
        }

        // Caption extraction from embed
        final captionMatch = RegExp(
          r'<div class="Caption"[^>]*>([\s\S]*?)<\/div>',
          caseSensitive: false,
        ).firstMatch(html);
        if (captionMatch != null && captionMatch.group(1) != null) {
          caption = _cleanHtmlTags(captionMatch.group(1)!);
        }

        // Author username extraction
        final usernameMatch = RegExp(
          r'<a class="UsernameText"[^>]*>([\s\S]*?)<\/a>',
          caseSensitive: false,
        ).firstMatch(html);
        if (usernameMatch != null && usernameMatch.group(1) != null) {
          authorUsername = _cleanHtmlTags(usernameMatch.group(1)!);
        }

        if (embedItems.isNotEmpty) {
          return InstagramResolvedData(
            mediaItems: embedItems,
            caption: caption,
            authorUsername: authorUsername,
          );
        }
      }
    } catch (e) {
      debugPrint('Strategy 3 (Embed page) error: $e');
    }

    // Strategy 4: Instagram oEmbed API fallback
    try {
      final oembedUrl =
          'https://www.instagram.com/api/v1/oembed/?url=https://www.instagram.com/p/$shortcode/';
      final response = await _fetch(
        Uri.parse(oembedUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final thumbnailUrl = data['thumbnail_url'] as String?;
        final title = data['title'] as String?;
        final authorName = data['author_name'] as String?;

        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
          return InstagramResolvedData(
            mediaItems: [InstagramMediaItem(url: thumbnailUrl, isVideo: false)],
            caption: title,
            authorUsername: authorName,
          );
        }
      }
    } catch (e) {
      debugPrint('Strategy 4 (oEmbed) error: $e');
    }

    // Strategy 5: High-availability external proxy fallback (VKR / Cobalt / DDInstagram)
    try {
      final proxyUrl = Uri.parse(
        'https://api.vkrdownloader.com/server?vkr=https://www.instagram.com/p/$shortcode/',
      );
      final response = await _fetch(proxyUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final dataObj = data['data'] as Map<String, dynamic>?;
        if (dataObj != null) {
          final downloads = dataObj['downloads'] as List<dynamic>?;
          final List<InstagramMediaItem> proxyItems = [];
          if (downloads != null && downloads.isNotEmpty) {
            for (final d in downloads) {
              final url = d['url'] as String?;
              final isVideo = d['format'] == 'mp4' || d['type'] == 'video';
              if (url != null && url.isNotEmpty) {
                proxyItems.add(InstagramMediaItem(url: url, isVideo: isVideo));
              }
            }
          }

          if (proxyItems.isNotEmpty) {
            return InstagramResolvedData(
              mediaItems: proxyItems,
              caption: dataObj['title'] as String?,
              authorUsername: dataObj['author'] as String?,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Strategy 5 (Proxy fallback) error: $e');
    }

    return null;
  }

  static String _sanitizeMediaUrl(String raw) {
    var clean = raw.trim();
    clean = clean.replaceAll('&amp;', '&');
    clean = clean.replaceAll(r'\u0026', '&');
    clean = clean.replaceAll(r'\/', '/');
    clean = clean.replaceAll(RegExp(r'^["' "'" r']+|["' "'" r']+$'), '');
    return clean;
  }

  /// Scans raw HTML for a JSON value (object or array) that starts right
  /// after the given key, using brace/bracket balancing so it survives
  /// nested objects (e.g. carousel "edges" arrays) that a non-greedy regex
  /// would truncate.
  static String? _extractBalancedJson(String html, String key) {
    final keyIdx = html.indexOf('"$key"');
    if (keyIdx == -1) return null;
    final colonIdx = html.indexOf(':', keyIdx);
    if (colonIdx == -1) return null;

    var i = colonIdx + 1;
    while (i < html.length && html[i] != '{' && html[i] != '[') {
      i++;
    }
    if (i >= html.length) return null;

    final openChar = html[i];
    final closeChar = openChar == '{' ? '}' : ']';
    final start = i;
    var depth = 0;
    var inString = false;
    var escape = false;

    for (; i < html.length; i++) {
      final c = html[i];
      if (inString) {
        if (escape) {
          escape = false;
        } else if (c == '\\') {
          escape = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
        continue;
      }
      if (c == openChar) depth++;
      if (c == closeChar) {
        depth--;
        if (depth == 0) {
          return html.substring(start, i + 1);
        }
      }
    }
    return null;
  }

  static String _cleanHtmlTags(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  InstagramResolvedData? _parseGraphQLMedia(Map<String, dynamic> media) {
    final List<InstagramMediaItem> items = [];

    // Check carousel
    if (media['edge_sidecar_to_children'] != null) {
      final edges =
          media['edge_sidecar_to_children']['edges'] as List<dynamic>?;
      if (edges != null && edges.isNotEmpty) {
        for (final edge in edges) {
          final node = edge['node'] as Map<String, dynamic>?;
          if (node != null) {
            if (node['is_video'] == true && node['video_url'] != null) {
              items.add(InstagramMediaItem(
                url: _sanitizeMediaUrl(node['video_url'] as String),
                isVideo: true,
              ));
            } else if (node['display_url'] != null) {
              items.add(InstagramMediaItem(
                url: _sanitizeMediaUrl(node['display_url'] as String),
                isVideo: false,
              ));
            }
          }
        }
      }
    }

    // Single media
    if (items.isEmpty) {
      if (media['is_video'] == true && media['video_url'] != null) {
        items.add(InstagramMediaItem(
          url: _sanitizeMediaUrl(media['video_url'] as String),
          isVideo: true,
        ));
      } else if (media['display_url'] != null) {
        items.add(InstagramMediaItem(
          url: _sanitizeMediaUrl(media['display_url'] as String),
          isVideo: false,
        ));
      } else if (media['video_url'] != null) {
        items.add(InstagramMediaItem(
          url: _sanitizeMediaUrl(media['video_url'] as String),
          isVideo: true,
        ));
      }
    }

    // Caption
    String? caption;
    if (media['edge_media_to_caption'] != null) {
      final captionEdges =
          media['edge_media_to_caption']['edges'] as List<dynamic>?;
      if (captionEdges != null && captionEdges.isNotEmpty) {
        caption = captionEdges.first['node']?['text'] as String?;
      }
    }

    // Owner info
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
    return null;
  }

  InstagramResolvedData? _parseWebJsonMedia(Map<String, dynamic> media) {
    final List<InstagramMediaItem> items = [];

    // Check carousel items
    if (media['carousel_media'] != null) {
      final carouselList = media['carousel_media'] as List<dynamic>?;
      if (carouselList != null) {
        for (final item in carouselList) {
          if (item is Map<String, dynamic>) {
            final isVideo = item['media_type'] == 2;
            String? url;
            if (isVideo && item['video_versions'] != null) {
              final vids = item['video_versions'] as List<dynamic>?;
              if (vids != null && vids.isNotEmpty) {
                url = vids.first['url'] as String?;
              }
            } else if (item['image_versions2']?['candidates'] != null) {
              final imgs =
                  item['image_versions2']['candidates'] as List<dynamic>?;
              if (imgs != null && imgs.isNotEmpty) {
                url = imgs.first['url'] as String?;
              }
            }
            if (url != null) {
              items.add(InstagramMediaItem(
                url: _sanitizeMediaUrl(url),
                isVideo: isVideo,
              ));
            }
          }
        }
      }
    }

    // Single media items
    if (items.isEmpty) {
      if (media['video_versions'] != null) {
        final vids = media['video_versions'] as List<dynamic>?;
        if (vids != null && vids.isNotEmpty) {
          final url = vids.first['url'] as String?;
          if (url != null) {
            items.add(InstagramMediaItem(
              url: _sanitizeMediaUrl(url),
              isVideo: true,
            ));
          }
        }
      } else if (media['image_versions2']?['candidates'] != null) {
        final imgs = media['image_versions2']['candidates'] as List<dynamic>?;
        if (imgs != null && imgs.isNotEmpty) {
          final url = imgs.first['url'] as String?;
          if (url != null) {
            items.add(InstagramMediaItem(
              url: _sanitizeMediaUrl(url),
              isVideo: false,
            ));
          }
        }
      }
    }

    String? caption;
    if (media['caption'] != null && media['caption']['text'] != null) {
      caption = media['caption']['text'] as String?;
    }

    String? authorUsername;
    if (media['user']?['username'] != null) {
      authorUsername = media['user']['username'] as String?;
    }

    if (items.isNotEmpty) {
      return InstagramResolvedData(
        mediaItems: items,
        caption: caption,
        authorUsername: authorUsername,
      );
    }
    return null;
  }

  /// Backward compatibility alias
  Future<InstagramResolvedData?> resolveReelData(String rawUrl) async {
    return resolveInstagramData(rawUrl);
  }

  /// Downloads Instagram Post/Reel media files and saves them permanently.
  Future<InstagramDownloadResult> downloadPost({
    required String instagramUrl,
    void Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.1, 'Bağlantı doğrulanıyor...');

    if (!isValidInstagramUrl(instagramUrl)) {
      throw const FormatException(
          'Lütfen geçerli bir Instagram linki giriniz (örn: instagram.com/reel/... veya p/...).');
    }

    final shortcode = await resolveCanonicalShortcode(instagramUrl) ??
        extractShortcode(instagramUrl);
    onProgress?.call(0.25, 'Gönderi bilgileri çekiliyor...');

    final resolved = await resolveInstagramData(instagramUrl);
    if (resolved == null || resolved.mediaItems.isEmpty) {
      throw const HttpException(
        'Medya indirilemedi. Gönderi gizli bir hesaba ait olabilir veya Instagram bu bağlantıyı kısıtlamış olabilir. Dilerseniz medyayı galeri seçeneğiyle doğrudan yükleyebilirsiniz.',
      );
    }

    // Web platform: Convert media images to data URIs or proxied URLs to avoid CORS blocking and link expiration
    if (kIsWeb) {
      final List<String> webMediaUrls = [];
      for (int i = 0; i < resolved.mediaItems.length; i++) {
        final item = resolved.mediaItems[i];
        final sanitizedUrl = _sanitizeMediaUrl(item.url);
        if (item.isVideo) {
          final proxyUrl =
              'https://be-yourself-project-orpin.vercel.app/api/proxy-image?url=${Uri.encodeComponent(sanitizedUrl)}';
          webMediaUrls.add(proxyUrl);
        } else {
          String? dataUri;
          final proxyCandidates = [
            '/api/proxy-image?url=${Uri.encodeComponent(sanitizedUrl)}',
            'https://be-yourself-project-orpin.vercel.app/api/proxy-image?url=${Uri.encodeComponent(sanitizedUrl)}',
            'https://corsproxy.io/?url=${Uri.encodeComponent(sanitizedUrl)}',
            'https://api.allorigins.win/raw?url=${Uri.encodeComponent(sanitizedUrl)}',
          ];

          for (final proxy in proxyCandidates) {
            try {
              final res = await http
                  .get(Uri.parse(proxy))
                  .timeout(const Duration(seconds: 6));
              if (res.statusCode == 200 && res.bodyBytes.length > 64) {
                final isError = res.bodyBytes.length < 1000 &&
                    (res.bodyBytes.first == 60 || res.bodyBytes.first == 123);
                if (!isError) {
                  final base64Str = base64Encode(res.bodyBytes);
                  dataUri = 'data:image/jpeg;base64,$base64Str';
                  break;
                }
              }
            } catch (_) {}
          }

          webMediaUrls.add(dataUri ??
              'https://be-yourself-project-orpin.vercel.app/api/proxy-image?url=${Uri.encodeComponent(sanitizedUrl)}');
        }
      }

      onProgress?.call(1.0, 'İndirme tamamlandı! ✨');
      return InstagramDownloadResult(
        filePaths: webMediaUrls,
        caption: resolved.caption,
        authorUsername: resolved.authorUsername,
        authorFullName: resolved.authorFullName,
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
      final sanitizedUrl = _sanitizeMediaUrl(item.url);
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

      http.Response? response;
      try {
        response = await http.get(
          Uri.parse(sanitizedUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
            'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            'Referer': 'https://www.instagram.com/',
          },
        ).timeout(const Duration(seconds: 25));
      } catch (e) {
        debugPrint('Direct image download attempt 1 failed: $e');
      }

      // Retry without Referer if first attempt failed or returned error
      if (response == null ||
          response.statusCode != 200 ||
          response.bodyBytes.length < 64 ||
          (response.bodyBytes.length < 1000 &&
              (response.bodyBytes.first == 60 || response.bodyBytes.first == 123))) {
        try {
          response = await http.get(
            Uri.parse(sanitizedUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
              'Accept': '*/*',
            },
          ).timeout(const Duration(seconds: 25));
        } catch (e) {
          debugPrint('Direct image download attempt 2 failed: $e');
        }
      }

      if (response != null &&
          response.statusCode == 200 &&
          response.bodyBytes.length > 64) {
        // Ensure not XML/HTML error text
        final isErrorText = response.bodyBytes.length < 1000 &&
            (response.bodyBytes.first == 60 || response.bodyBytes.first == 123);
        if (!isErrorText) {
          await file.writeAsBytes(response.bodyBytes);
          if (await file.exists() && (await file.length()) > 0) {
            downloadedFilePaths.add(file.path);
          }
        }
      }
    }

    if (downloadedFilePaths.isEmpty) {
      throw const HttpException('Medya dosyaları indirilemedi veya kaydedilemedi.');
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
