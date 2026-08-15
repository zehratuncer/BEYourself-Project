import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/core/utils/media_type_helper.dart';
import 'package:be_yourself/features/media/services/media_storage_service.dart';
import 'package:be_yourself/shared/widgets/app_video_player.dart';

class AppMediaImage extends StatelessWidget {
  const AppMediaImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0.0,
    this.isDarkMode = false,
  });

  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isDarkMode;

  static String proxyMediaUrl(String url) {
    final clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      return clean;
    }
    // If it's already going through proxy, keep as is
    if (clean.contains('/api/proxy-image') ||
        clean.contains('corsproxy.io') ||
        clean.contains('allorigins.win')) {
      return clean;
    }
    // Proxy Instagram CDN URLs to bypass CORS and Referer restrictions
    if (clean.contains('cdninstagram.com') ||
        clean.contains('fbcdn.net') ||
        clean.contains('instagram.com')) {
      return 'https://be-yourself-project-orpin.vercel.app/api/proxy-image?url=${Uri.encodeComponent(clean)}';
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    final cleanPath = imagePath.trim();
    if (cleanPath.isEmpty) {
      content = _buildPlaceholder(context);
    } else if (isVideoMedia(cleanPath)) {
      content = AppVideoPlayer(
        videoPath: cleanPath,
        height: height ?? 220,
        borderRadius: borderRadius,
        fit: fit,
        autoPlay: false,
      );
    } else if (cleanPath.startsWith('data:image/')) {
      try {
        final base64Data = cleanPath.split(',').last;
        final bytes = base64Decode(base64Data);
        content = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
        );
      } catch (_) {
        content = _buildPlaceholder(context);
      }
    } else if (cleanPath.startsWith('http://') ||
        cleanPath.startsWith('https://') ||
        cleanPath.startsWith('blob:')) {
      final targetUrl = proxyMediaUrl(cleanPath);

      content = Image.network(
        targetUrl,
        width: width,
        height: height,
        fit: fit,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
          'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final totalBytes = loadingProgress.expectedTotalBytes;
          final loadedBytes = loadingProgress.cumulativeBytesLoaded;
          final value = totalBytes != null && totalBytes > 0
              ? loadedBytes / totalBytes
              : null;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2.0,
                  color: isDarkMode
                      ? AppColors.primaryBlueLight
                      : AppColors.primaryBlue,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // If proxied request failed and it wasn't the raw URL, retry raw URL as fallback
          if (targetUrl != cleanPath) {
            return Image.network(
              cleanPath,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (ctx, err, st) => _buildPlaceholder(context),
            );
          }
          return _buildPlaceholder(context);
        },
      );
    } else {
      // Local File (with dynamic iOS Sandbox UUID recovery)
      final normalized = MediaStorageService.normalizeFilePath(cleanPath);
      final resolvedFile = MediaStorageService.instance.resolveLocalFileSync(normalized);
      if (resolvedFile.existsSync() && resolvedFile.lengthSync() > 0) {
        content = Image.file(
          resolvedFile,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
        );
      } else if (cleanPath.startsWith('assets/')) {
        content = Image.asset(
          cleanPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
        );
      } else {
        // Asynchronous fallback check if sync missed it
        content = FutureBuilder<File?>(
          future: MediaStorageService.instance.resolveLocalFile(normalized),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null &&
                snapshot.data!.existsSync() &&
                snapshot.data!.lengthSync() > 0) {
              return Image.file(
                snapshot.data!,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(context),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return _buildPlaceholder(context);
          },
        );
      }
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: isDarkMode
          ? Colors.white.withAlpha(8)
          : Colors.black.withAlpha(6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 32,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 6),
            Text(
              'Görsel Yüklenemedi',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
