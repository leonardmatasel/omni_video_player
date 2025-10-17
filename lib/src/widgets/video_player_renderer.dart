import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/controllers/default_playback_controller.dart';
import 'package:omni_video_player/src/navigation/route_aware_listener.dart';
import 'package:omni_video_player/src/widgets/adaptive_video_player_display.dart';
import 'package:omni_video_player/src/widgets/fade_overlay_switcher.dart';
import 'package:omni_video_player/src/widgets/player/video_player_thumbnail_preview.dart';
import 'package:omni_video_player/src/widgets/video_overlay_controls.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A comprehensive video player widget that manages video rendering,
/// overlay controls, visibility detection, and thumbnail preview.
///
/// This widget combines multiple functionalities:
/// - Displays a blurred circular background overlay with configurable color and opacity.
/// - Shows adaptive video player display for responsive video rendering.
/// - Integrates overlay controls for playback interaction.
/// - Detects widget visibility to automatically pause playback when the video is out of view.
/// - Displays video thumbnail preview at the start or end of playback based on configuration.
///
/// This widget is designed to be used within apps that require
/// full-featured video playback with smooth transitions and state management.
class VideoPlayerRenderer extends StatefulWidget {
  /// Configuration options for the video player (theme, thumbnail, behavior).
  final VideoPlayerConfiguration options;

  /// Callback handlers for video player events.
  final VideoPlayerCallbacks callbacks;

  /// Controller managing video playback state and commands.
  final OmniPlaybackController controller;

  const VideoPlayerRenderer({
    super.key,
    required this.controller,
    required this.options,
    required this.callbacks,
  });

  @override
  VideoPlayerRendererState createState() => VideoPlayerRendererState();
}

class VideoPlayerRendererState extends State<VideoPlayerRenderer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    final aspectRatio =
        widget.options.playerUIVisibilityOptions.customAspectRatioNormal ??
        widget.controller.size.width / widget.controller.size.height;

    return VideoOverlayControls(
      controller: widget.controller,
      options: widget.options,
      callbacks: widget.callbacks,
      child: Stack(
        children: [
          // Video player with fade transition and visibility detection
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.shapes.borderRadius),
              child: FadeOverlaySwitcher(
                duration: const Duration(milliseconds: 400),
                child: VisibilityDetector(
                  key: Key(hashCode.toString()),
                  onVisibilityChanged: (visibilityInfo) async {
                    if (!context.mounted) {
                      return;
                    }

                    if (visibilityInfo.visibleFraction > 0 &&
                        widget.controller.videoUrl != null &&
                        !VideoPlaybackControllerPool().contains(
                          widget.controller.videoUrl!,
                        ) &&
                        !widget.controller.isFullScreen) {
                      widget.controller.loadVideoSource(
                        widget.options.videoSourceConfiguration,
                      );
                    } else if (visibilityInfo.visibleFraction <= 0 &&
                        widget.controller.videoUrl != null &&
                        !widget.controller.isFullScreen) {
                      await VideoPlaybackControllerPool().release(
                        uri: widget.controller.videoUrl!,
                      );
                    }

                    if (visibilityInfo.visibleFraction == 1 &&
                        !widget.controller.isFullyVisible) {
                      widget.controller.isFullyVisible = true;
                    } else {
                      widget.controller.isFullyVisible = false;
                    }

                    // Automatically pause video when not visible and not fullscreen
                    if (visibilityInfo.visibleFraction == 0.0 &&
                        widget.controller.isPlaying &&
                        !widget.controller.isFullScreen) {
                      widget.controller.pause();
                    }
                    if (!widget.controller.hasStarted &&
                        widget.options.videoSourceConfiguration.autoPlay &&
                        visibilityInfo.visibleFraction == 1) {
                      widget.controller.play();
                    }
                  },
                  child: RouteAwareListener(
                    onPopNext: (route) {
                      // Optionally restore orientation or other state on returning to this route
                    },
                    child: AdaptiveVideoPlayerDisplay(
                      controller: widget.controller,
                      isFullScreenDisplay: false,
                      aspectRatio: aspectRatio,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Conditionally show thumbnail preview at start or end of playback
          if (widget.options.customPlayerWidgets.thumbnail != null &&
              widget.options.playerUIVisibilityOptions.showThumbnailAtStart &&
              (!widget.controller.hasStarted || widget.controller.isFinished))
            Center(
              child: AspectRatio(
                aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    theme.shapes.borderRadius,
                  ),
                  child: VideoPlayerThumbnailPreview(
                    imageProvider:
                        widget.options.customPlayerWidgets.thumbnail!,
                    fit: widget.options.customPlayerWidgets.thumbnailFit,
                    backgroundColor: theme.colors.backgroundThumbnail,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.dispose();
    super.dispose();
  }
}

/// Custom painter that draws a blurred circular overlay with configurable color and transparency.
class _BlurredCirclePainter extends CustomPainter {
  final Color color;
  final int alpha;
  final Offset center;

  _BlurredCirclePainter({
    required this.color,
    required this.alpha,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    canvas.drawCircle(center, size.width * 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant _BlurredCirclePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.alpha != alpha ||
        oldDelegate.color != color;
  }
}

/// Widget that paints a moving blurred circle as a background effect.
class MovingBlurredCircleBackground extends StatefulWidget {
  final Color color;
  final int alpha;
  final Duration animationDuration;

  const MovingBlurredCircleBackground({
    super.key,
    this.color = Colors.red,
    this.alpha = 100,
    this.animationDuration = const Duration(seconds: 10),
  });

  @override
  State<MovingBlurredCircleBackground> createState() =>
      _MovingBlurredCircleBackgroundState();
}

class _MovingBlurredCircleBackgroundState
    extends State<MovingBlurredCircleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animationX;
  late Animation<double> _animationY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat(reverse: true);

    // Animations for center X and Y to move the blurred circle smoothly
    _animationX = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _animationY = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final center = Offset(
              constraints.maxWidth * _animationX.value,
              constraints.maxHeight * _animationY.value,
            );
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _BlurredCirclePainter(
                color: widget.color,
                alpha: widget.alpha,
                center: center,
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
