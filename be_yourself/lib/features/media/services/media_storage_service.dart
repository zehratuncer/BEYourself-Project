import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MediaStorageService {
  MediaStorageService._();
  static final MediaStorageService instance = MediaStorageService._();

  String? _cachedDocsPath;

  /// Initializes the storage service and pre-caches the documents directory path.
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cachedDocsPath = dir.path;
    } catch (e) {
      debugPrint('MediaStorageService init error: $e');
    }
  }

  Future<String> _getDocsPath() async {
    if (kIsWeb) return '';
    if (_cachedDocsPath != null) return _cachedDocsPath!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cachedDocsPath = dir.path;
      return _cachedDocsPath!;
    } catch (_) {
      return Directory.systemTemp.path;
    }
  }

  /// Copies a picked or downloaded file to permanent application documents directory.
  /// This ensures the file is not lost across app launches, iOS sandbox UUID changes, or tmp cleanups.
  Future<String> saveMediaLocally(
    File sourceFile, {
    String subDirectory = 'app_media',
    String? customPrefix,
  }) async {
    if (kIsWeb) return sourceFile.path;

    final docsPath = await _getDocsPath();
    final targetDir = Directory('$docsPath/$subDirectory');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final ext = sourceFile.path.contains('.')
        ? sourceFile.path.split('.').last.toLowerCase()
        : 'jpg';
    final randomSuffix = Random().nextInt(999999);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = customPrefix ?? 'media';
    final fileName = '${prefix}_${timestamp}_$randomSuffix.$ext';
    final targetFilePath = '${targetDir.path}/$fileName';

    final targetFile = await sourceFile.copy(targetFilePath);
    return targetFile.path;
  }

  /// Saves an XFile (picked from gallery/camera) locally.
  /// Works seamlessly across Web (Safari/Chrome), iOS, and Android.
  Future<String> saveXFileLocally(
    XFile sourceFile, {
    String subDirectory = 'app_media',
    String? customPrefix,
    bool? isVideo,
  }) async {
    final bool isVideoType = isVideo ??
        (customPrefix == 'video' ||
            sourceFile.name.toLowerCase().endsWith('.mp4') ||
            sourceFile.name.toLowerCase().endsWith('.mov') ||
            sourceFile.mimeType?.startsWith('video/') == true);

    if (kIsWeb) {
      if (isVideoType) {
        final rawPath = sourceFile.path;
        if (!rawPath.contains('.mp4') && !rawPath.contains('#video')) {
          return '$rawPath#video.mp4';
        }
        return rawPath;
      }

      try {
        final bytes = await sourceFile.readAsBytes();
        final mime = sourceFile.mimeType ??
            (sourceFile.name.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg');

        // For images on web, return persistent Data URI
        if (bytes.lengthInBytes < 8 * 1024 * 1024) {
          final base64Str = base64Encode(bytes);
          return 'data:$mime;base64,$base64Str';
        }
      } catch (e) {
        debugPrint('Web XFile read error: $e');
      }
      return sourceFile.path;
    }

    if (sourceFile.path.isEmpty || !File(sourceFile.path).existsSync()) {
      final bytes = await sourceFile.readAsBytes();
      final docsPath = await _getDocsPath();
      final targetDir = Directory('$docsPath/$subDirectory');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final defaultExt = isVideoType ? 'mp4' : 'jpg';
      final ext = sourceFile.name.contains('.')
          ? sourceFile.name.split('.').last.toLowerCase()
          : defaultExt;
      final randomSuffix = Random().nextInt(999999);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final prefix = customPrefix ?? (isVideoType ? 'video' : 'media');
      final fileName = '${prefix}_${timestamp}_$randomSuffix.$ext';
      final targetFilePath = '${targetDir.path}/$fileName';
      final targetFile = File(targetFilePath);
      await targetFile.writeAsBytes(bytes);
      return targetFile.path;
    }

    final file = File(sourceFile.path);
    return saveMediaLocally(
      file,
      subDirectory: subDirectory,
      customPrefix: customPrefix ?? (isVideoType ? 'video' : 'media'),
    );
  }

  /// Copies an avatar photo permanently to `user_avatars` directory.
  Future<String> saveAvatarLocally(File sourceFile) async {
    return saveMediaLocally(
      sourceFile,
      subDirectory: 'user_avatars',
      customPrefix: 'avatar',
    );
  }

  /// Saves an avatar XFile permanently (Web and Native safe).
  Future<String> saveAvatarXFileLocally(XFile sourceFile) async {
    return saveXFileLocally(
      sourceFile,
      subDirectory: 'user_avatars',
      customPrefix: 'avatar',
    );
  }

  /// Normalizes any file path by stripping `file://` URI scheme and trimming.
  static String normalizeFilePath(String path) {
    var p = path.trim();
    if (p.startsWith('file://')) {
      p = p.replaceFirst(RegExp(r'^file:\/{2,3}'), '/');
      if (!p.startsWith('/')) {
        p = '/$p';
      }
    }
    return p;
  }

  /// Resolves any local media path (handling iOS Sandbox UUID changes across app launches).
  Future<File?> resolveLocalFile(String? rawPath) async {
    if (rawPath == null || rawPath.trim().isEmpty) return null;
    final cleanPath = normalizeFilePath(rawPath);

    // 1. Direct check
    final directFile = File(cleanPath);
    if (await directFile.exists()) {
      return directFile;
    }

    // 1.1 iOS /private/var vs /var check
    if (cleanPath.startsWith('/var/')) {
      final privFile = File('/private$cleanPath');
      if (await privFile.exists()) return privFile;
    } else if (cleanPath.startsWith('/private/var/')) {
      final varFile = File(cleanPath.substring(8));
      if (await varFile.exists()) return varFile;
    }

    // 2. Dynamic resolution using current documents directory
    final docsPath = await _getDocsPath();
    final fileName = cleanPath.split(RegExp(r'[/\\]')).last;

    final candidatePaths = [
      '$docsPath/app_media/$fileName',
      '$docsPath/instagram_media/$fileName',
      '$docsPath/user_avatars/$fileName',
      '$docsPath/$fileName',
      if (docsPath.startsWith('/var/')) ...[
        '/private$docsPath/app_media/$fileName',
        '/private$docsPath/instagram_media/$fileName',
        '/private$docsPath/user_avatars/$fileName',
        '/private$docsPath/$fileName',
      ],
    ];

    for (final candidate in candidatePaths) {
      final file = File(candidate);
      if (await file.exists()) {
        return file;
      }
    }

    // Fallback: return directFile even if not yet existing
    return directFile;
  }

  /// Synchronously attempts to resolve the local file if `_cachedDocsPath` is available.
  File resolveLocalFileSync(String rawPath) {
    final cleanPath = normalizeFilePath(rawPath);
    final directFile = File(cleanPath);
    if (directFile.existsSync()) {
      return directFile;
    }

    // iOS /private/var vs /var check
    if (cleanPath.startsWith('/var/')) {
      final privFile = File('/private$cleanPath');
      if (privFile.existsSync()) return privFile;
    } else if (cleanPath.startsWith('/private/var/')) {
      final varFile = File(cleanPath.substring(8));
      if (varFile.existsSync()) return varFile;
    }

    if (_cachedDocsPath != null) {
      final fileName = cleanPath.split(RegExp(r'[/\\]')).last;
      final candidatePaths = [
        '$_cachedDocsPath/app_media/$fileName',
        '$_cachedDocsPath/instagram_media/$fileName',
        '$_cachedDocsPath/user_avatars/$fileName',
        '$_cachedDocsPath/$fileName',
        if (_cachedDocsPath!.startsWith('/var/')) ...[
          '/private$_cachedDocsPath/app_media/$fileName',
          '/private$_cachedDocsPath/instagram_media/$fileName',
          '/private$_cachedDocsPath/user_avatars/$fileName',
          '/private$_cachedDocsPath/$fileName',
        ],
      ];

      for (final candidate in candidatePaths) {
        final file = File(candidate);
        if (file.existsSync()) {
          return file;
        }
      }
    }

    return directFile;
  }
}
