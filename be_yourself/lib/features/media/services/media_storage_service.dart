import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class MediaStorageService {
  MediaStorageService._();
  static final MediaStorageService instance = MediaStorageService._();

  String? _cachedDocsPath;

  /// Initializes the storage service and pre-caches the documents directory path.
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cachedDocsPath = dir.path;
    } catch (e) {
      debugPrint('MediaStorageService init error: $e');
    }
  }

  Future<String> _getDocsPath() async {
    if (_cachedDocsPath != null) return _cachedDocsPath!;
    final dir = await getApplicationDocumentsDirectory();
    _cachedDocsPath = dir.path;
    return _cachedDocsPath!;
  }

  /// Copies a picked or downloaded file to permanent application documents directory.
  /// This ensures the file is not lost across app launches, iOS sandbox UUID changes, or tmp cleanups.
  Future<String> saveMediaLocally(
    File sourceFile, {
    String subDirectory = 'app_media',
    String? customPrefix,
  }) async {
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

  /// Copies an avatar photo permanently to `user_avatars` directory.
  Future<String> saveAvatarLocally(File sourceFile) async {
    return saveMediaLocally(
      sourceFile,
      subDirectory: 'user_avatars',
      customPrefix: 'avatar',
    );
  }

  /// Resolves any local media path (handling iOS Sandbox UUID changes across app launches).
  Future<File?> resolveLocalFile(String? rawPath) async {
    if (rawPath == null || rawPath.trim().isEmpty) return null;
    final cleanPath = rawPath.trim();

    // 1. Direct check
    final directFile = File(cleanPath);
    if (await directFile.exists()) {
      return directFile;
    }

    // 2. Dynamic resolution using current documents directory
    final docsPath = await _getDocsPath();
    final fileName = cleanPath.split(RegExp(r'[/\\]')).last;

    final candidatePaths = [
      '$docsPath/app_media/$fileName',
      '$docsPath/instagram_media/$fileName',
      '$docsPath/user_avatars/$fileName',
      '$docsPath/$fileName',
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
    final cleanPath = rawPath.trim();
    final directFile = File(cleanPath);
    if (directFile.existsSync()) {
      return directFile;
    }

    if (_cachedDocsPath != null) {
      final fileName = cleanPath.split(RegExp(r'[/\\]')).last;
      final candidatePaths = [
        '$_cachedDocsPath/app_media/$fileName',
        '$_cachedDocsPath/instagram_media/$fileName',
        '$_cachedDocsPath/user_avatars/$fileName',
        '$_cachedDocsPath/$fileName',
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
