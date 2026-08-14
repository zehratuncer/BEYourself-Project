// Centralized helper for robust media type detection

bool isVideoMedia(String? path) {
  if (path == null || path.trim().isEmpty) return false;
  final clean = path.trim().toLowerCase();
  
  // Extract path without query parameters or fragments
  final withoutQuery = clean.split('?').first.split('#').first;

  // 1. Direct Extension Checks
  if (withoutQuery.endsWith('.mp4') ||
      withoutQuery.endsWith('.mov') ||
      withoutQuery.endsWith('.webm') ||
      withoutQuery.endsWith('.m4v') ||
      withoutQuery.endsWith('.avi') ||
      withoutQuery.endsWith('.mkv') ||
      withoutQuery.endsWith('.3gp') ||
      withoutQuery.endsWith('.ts')) {
    return true;
  }

  // 2. Query/CDN/Tag embedded video indicators
  if (clean.contains('.mp4') ||
      clean.contains('.mov') ||
      clean.contains('.webm') ||
      clean.contains('.m4v') ||
      clean.contains('/video/') ||
      clean.contains('/reels/') ||
      clean.contains('#video') ||
      clean.contains('type=video') ||
      clean.contains('is_video=true') ||
      clean.contains('video=true') ||
      clean.contains('data:video/') ||
      clean.contains('video_url') ||
      clean.contains('videoplayback') ||
      clean.contains('fna.fbcdn.net/o1/v/') ||
      clean.contains('bytestart') ||
      clean.contains('app_media/video_') ||
      clean.contains('customprefix=video')) {
    return true;
  }

  return false;
}
