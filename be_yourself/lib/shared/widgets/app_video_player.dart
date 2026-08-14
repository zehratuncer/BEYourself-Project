import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/media/services/media_storage_service.dart';

class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer({
    super.key,
    required this.videoPath,
    this.autoPlay = false,
    this.showControls = true,
    this.height = 220,
    this.borderRadius = 16.0,
    this.fit = BoxFit.contain,
  });

  final String videoPath;
  final bool autoPlay;
  final bool showControls;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _controller?.dispose();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });

    try {
      final String path = widget.videoPath.trim();
      if (path.startsWith('http://') ||
          path.startsWith('https://') ||
          path.startsWith('blob:')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else {
        final resolvedFile = await MediaStorageService.instance.resolveLocalFile(path) ??
            MediaStorageService.instance.resolveLocalFileSync(path);
        _controller = VideoPlayerController.file(resolvedFile);
      }

      await _controller!.initialize();
      _controller!.setLooping(true);

      if (widget.autoPlay) {
        try {
          await _controller!.play();
        } catch (e) {
          debugPrint('Autoplay with sound blocked: $e, falling back to muted autoplay');
          try {
            await _controller!.setVolume(0.0);
            await _controller!.play();
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video player initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showOverlay = true;
      } else {
        _controller!.play();
        _showOverlay = false;
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      final currentVolume = _controller!.value.volume;
      _controller!.setVolume(currentVolume > 0 ? 0.0 : 1.0);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, color: Colors.white70, size: 40),
              SizedBox(height: 8),
              Text(
                'Video yüklenemedi',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlueLight,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final isPlaying = _controller!.value.isPlaying;
    final isMuted = _controller!.value.volume == 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player Surface
            Center(
              child: widget.fit == BoxFit.cover
                  ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width > 0
                              ? _controller!.value.size.width
                              : 1080,
                          height: _controller!.value.size.height > 0
                              ? _controller!.value.size.height
                              : 1920,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    )
                  : AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
            ),

            // Tap detector overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showOverlay = !_showOverlay;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: isPlaying && !_showOverlay
                      ? Colors.transparent
                      : Colors.black.withAlpha(80),
                ),
              ),
            ),

            // Center Play / Pause Icon
            if (!isPlaying || _showOverlay)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),

            // Top Bar: Mute button
            if (_showOverlay || !isPlaying)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

            // Bottom Progress Bar & Timers
            if (widget.showControls && (_showOverlay || !isPlaying))
              Positioned(
                bottom: 8,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primaryBlueLight,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: _controller!,
                          builder: (context, VideoPlayerValue value, child) {
                            return Text(
                              _formatDuration(value.position),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        Text(
                          _formatDuration(_controller!.value.duration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
