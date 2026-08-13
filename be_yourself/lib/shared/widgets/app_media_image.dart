import 'dart:io';
import 'package:flutter/material.dart';
import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/media/services/media_storage_service.dart';

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

  @override
  Widget build(BuildContext context) {
    Widget content;

    final cleanPath = imagePath.trim();
    if (cleanPath.isEmpty) {
      content = _buildPlaceholder(context);
    } else if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      content = Image.network(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final totalBytes = loadingProgress.expectedTotalBytes;
          final loadedBytes = loadingProgress.cumulativeBytesLoaded;
          final value = totalBytes != null && totalBytes > 0
              ? loadedBytes / totalBytes
              : null;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2.2,
                  color: isDarkMode
                      ? AppColors.primaryBlueLight
                      : AppColors.primaryBlue,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    } else {
      // Local File (with dynamic iOS Sandbox UUID recovery)
      final resolvedFile = MediaStorageService.instance.resolveLocalFileSync(cleanPath);
      if (resolvedFile.existsSync()) {
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
          future: MediaStorageService.instance.resolveLocalFile(cleanPath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null &&
                snapshot.data!.existsSync()) {
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
              size: 36,
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
