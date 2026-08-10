import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/navigation/route_aware_listener.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_viewport.dart';
import 'package:omni_video_player/src/utils/conditional_parent.dart';
import 'package:omni_video_player/src/utils/overlay_transition_switcher.dart';
import 'package:omni_video_player/src/_core/omni_video_player_thumbnail.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A full-featured video player widget that handles:
/// - Video rendering and visibility detection
/// - Overlay controls and transitions
/// - Thumbnail display before/after playback
/// - Auto-pause when out of view
class OmniVideoPlayerView extends StatefulWidget {
  final VideoPlayerConfiguration configuration;
  final VideoPlayerCallbacks callbacks;
  final OmniPlaybackController controller;

  /// Invoked when the player is fully out of view and should release its
  /// controller to free the native decoder (see initializer's off-view path).
  final VoidCallback? onReleaseForOffView;

  const OmniVideoPlayerView({
    super.key,
    required this.controller,
    required this.configuration,
    required this.callbacks,
    this.onReleaseForOffView,
  });

  @override
  State<OmniVideoPlayerView> createState() => _OmniVideoPlayerViewState();
}

class _OmniVideoPlayerViewState extends State<OmniVideoPlayerView> {
  OmniPlaybackController get controller => widget.controller;
  VideoPlayerConfiguration get config => widget.configuration;
  VideoPlayerCallbacks get callbacks => widget.callbacks;

  @override
  void initState() {
    super.initState();
    if (!controller.isDisposed) {
      controller.addListener(_onControllerUpdated);
    }
  }

  @override
  void didUpdateWidget(covariant OmniVideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller instance is swapped without this State being recreated,
    // move the listener and dispose the old controller so it doesn't leak its
    // native decoder (the State otherwise only cleans up in dispose()).
    if (!identical(oldWidget.controller, controller)) {
      oldWidget.controller.removeListener(_onControllerUpdated);
      if (!oldWidget.controller.isDisposed) oldWidget.controller.dispose();
      if (!controller.isDisposed) controller.addListener(_onControllerUpdated);
    }
  }

  // Snapshot of only the coarse controller properties this widget's own build
  // reads. The dynamic children (viewport, controls overlay, seek bar) already
  // rebuild via their own AnimatedBuilders, so a full setState here on every
  // ~5x/sec position tick just wastes frame budget and causes jank. (S1)
  bool _lastReady = false;
  Size _lastSize = Size.zero;
  bool _lastStarted = false;
  bool _lastFinished = false;

  void _onControllerUpdated() {
    if (!mounted) return;
    final ready = controller.isReady;
    final size = controller.size;
    final started = controller.hasStarted;
    final finished = controller.isFinished;
    if (ready == _lastReady &&
        size == _lastSize &&
        started == _lastStarted &&
        finished == _lastFinished) {
      return;
    }
    _lastReady = ready;
    _lastSize = size;
    _lastStarted = started;
    _lastFinished = finished;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;
    final aspectRatio = _getAspectRatio();

    return OmniVideoPlayerControlsOverlay(
      controller: controller,
      configuration: config,
      callbacks: callbacks,
      child: Stack(
        children: [
          ConditionalParent(
            wrapWhen:
                !widget
                    .configuration
                    .playerUIVisibilityOptions
                    .fitVideoToBounds ||
                _getAspectRatio() < 1,
            wrapWith: (ctx, child) => Positioned.fill(child: child),
            child: _buildVideoDisplay(context, theme, aspectRatio),
          ),
          if (_shouldShowThumbnailPreview())
            Positioned.fill(
              child: Center(child: _buildThumbnailPreview(theme, aspectRatio)),
            ),
          if (!controller.isReady)
            Positioned.fill(
              child: Center(child: config.customPlayerWidgets.loadingWidget),
            ),
        ],
      ),
    );
  }

  double _getAspectRatio() {
    final customRatio =
        config.playerUIVisibilityOptions.customAspectRatioNormal;
    if (customRatio != null) return customRatio;

    final size = controller.size;
    return size.width / size.height;
  }

  Widget _buildVideoDisplay(
    BuildContext context,
    OmniVideoPlayerThemeData theme,
    double aspectRatio,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.shapes.borderRadius),
      child: OverlayTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        child: VisibilityDetector(
          key: Key('video-visibility-${controller.hashCode}'),
          onVisibilityChanged: _handleVisibilityChanged,
          child: RouteAwareListener(
            onPopNext: (_) {},
            child: OmniVideoPlayerViewport(
              controller: controller,
              isFullScreenDisplay: false,
              aspectRatio: aspectRatio,
            ),
          ),
        ),
      ),
    );
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final visibleFraction = info.visibleFraction;
    controller.isFullyVisible = visibleFraction == 1;

    if (visibleFraction == 0 &&
        config.videoSourceConfiguration.pauseWhenOutOfView &&
        !controller.isFullScreen) {
      final src = config.videoSourceConfiguration;
      // Default: fully release the controller off-screen to free the native
      // decoder/heap; it re-initializes at the same position on return. Keep
      // the old pause-only behavior when the caller opted to keep the player
      // alive or for live streams (which can't resume at a position).
      if (!src.keepAlive && !controller.isLive) {
        widget.onReleaseForOffView?.call();
      } else if (controller.isPlaying) {
        controller.pause(useGlobalController: false);
      }
    }

    if (!controller.hasStarted &&
        config.videoSourceConfiguration.autoMuteOnStart &&
        visibleFraction == 1) {
      controller.mute();
    }

    if (!controller.hasStarted &&
        config.videoSourceConfiguration.autoPlay &&
        visibleFraction == 1) {
      controller.play();
    }
  }

  bool _shouldShowThumbnailPreview() {
    final showAtStart = config.playerUIVisibilityOptions.showThumbnailAtStart;
    final hasThumbnail = config.customPlayerWidgets.thumbnail != null;

    return hasThumbnail &&
        showAtStart &&
        (!controller.hasStarted || controller.isFinished);
  }

  Widget _buildThumbnailPreview(
    OmniVideoPlayerThemeData theme,
    double aspectRatio,
  ) {
    return AspectRatio(
      aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.shapes.borderRadius),
        child: VideoPlayerThumbnail(
          imageProvider: config.customPlayerWidgets.thumbnail!,
          fit: config.customPlayerWidgets.thumbnailFit,
          backgroundColor: theme.colors.backgroundThumbnail,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!controller.isDisposed) {
      controller.removeListener(_onControllerUpdated);
      controller.dispose();
    }
    super.dispose();
  }
}
