import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:be_yourself/core/config/supabase_config.dart';
import 'package:be_yourself/features/media/services/media_storage_service.dart';

class CloudMediaStorageService {
  CloudMediaStorageService._();
  static final CloudMediaStorageService instance = CloudMediaStorageService._();

  static const String _bucketName = 'media';

  SupabaseClient? get _client => SupabaseConfig.client;

  /// Uploads media to Supabase Storage in an isolated device folder.
  /// If Supabase is offline/uninitialized, safely falls back to local storage.
  Future<String> uploadMedia(
    XFile file,
    String deviceId, {
    bool isVideo = false,
  }) async {
    final client = _client;

    // Local fallback if Supabase is not available
    if (client == null) {
      return MediaStorageService.instance.saveXFileLocally(
        file,
        subDirectory: 'app_media',
        customPrefix: isVideo ? 'video' : 'photo',
        isVideo: isVideo,
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : (isVideo ? 'mp4' : 'jpg');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = Random().nextInt(999999);
      final pathInBucket = '$deviceId/${isVideo ? "video" : "photo"}_${timestamp}_$randomSuffix.$ext';

      final contentType = file.mimeType ?? (isVideo ? 'video/mp4' : 'image/jpeg');

      await client.storage.from(_bucketName).uploadBinary(
            pathInBucket,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final publicUrl = client.storage.from(_bucketName).getPublicUrl(pathInBucket);
      debugPrint('CloudMediaStorageService uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('CloudMediaStorageService upload error (falling back to local): $e');
      return MediaStorageService.instance.saveXFileLocally(
        file,
        subDirectory: 'app_media',
        customPrefix: isVideo ? 'video' : 'photo',
        isVideo: isVideo,
      );
    }
  }
}
