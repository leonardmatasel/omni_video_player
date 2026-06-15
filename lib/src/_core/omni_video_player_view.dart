import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/_core/omni_video_player_fullscreen.dart';
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

  const OmniVideoPlayerView({
    super.key,
    required this.controller,
    required this.configuration,
    required this.callbacks,
  });

  @override
  State<OmniVideoPlayerView> createState() => _OmniVideoPlayerViewState();
}

class _OmniVideoPlayerViewState extends State<OmniVideoPlayerView> {
  OmniPlaybackController get controller => widget.controller;
  VideoPlayerConfiguration get config => widget.configuration;
  VideoPlayerCallbacks get callbacks => widget.callbacks;

  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    if (!controller.isDisposed) {
      controller.addListener(_onControllerUpdated);
    }
    // When the fullscreen route is already open (e.g. playlist advance in
    // fullscreen, or wasLastVideoFullscreen), the VisibilityDetector behind
    // the route may never fire with visible fraction > 0.  Trigger autoplay
    // directly so the new video starts without user interaction.
    _autoPlayIfFullscreenOpen();
  }

  @override
  void didUpdateWidget(covariant OmniVideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (!oldWidget.controller.isDisposed) {
        oldWidget.controller.removeListener(_onControllerUpdated);
      }
      if (!widget.controller.isDisposed) {
        widget.controller.addListener(_onControllerUpdated);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != null && _lastOrientation != orientation) {
      _handleOrientationChanged(orientation);
    }
    _lastOrientation = orientation;
  }

  void _handleOrientationChanged(Orientation orientation) {
    final isFullscreenOpen = GlobalPlaybackController().isFullscreenRouteOpen;

    if (orientation == Orientation.landscape && !isFullscreenOpen) {
      if (!controller.isDisposed) {
        controller.switchFullScreenMode(
          context,
          pageBuilder: (context) => OmniVideoPlayerTheme(
            data: config.playerTheme,
            child: OmniVideoPlayerFullscreen(
              controller: controller,
              configuration: config,
              callbacks: callbacks,
            ),
          ),
        );
      }
    } else if (orientation == Orientation.portrait && isFullscreenOpen) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _onControllerUpdated() {
    if (mounted) setState(() {});
  }

  /// Triggers autoplay when the fullscreen route is already open.
  ///
  /// The [VisibilityDetector] callback may never fire for a widget that
  /// starts fully occluded (behind the fullscreen route).  This method
  /// schedules a post-frame check so the fullscreen flag is guaranteed
  /// to be set, and then starts playback + optional auto-mute exactly
  /// as [_handleVisibilityChanged] would.
  void _autoPlayIfFullscreenOpen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || controller.isDisposed) return;

      final isFullscreenOpen = GlobalPlaybackController().isFullscreenRouteOpen;
      if (!isFullscreenOpen) return;

      if (!controller.hasStarted &&
          config.videoSourceConfiguration.autoMuteOnStart) {
        controller.mute();
      }

      if (!controller.hasStarted &&
          config.videoSourceConfiguration.autoPlay) {
        controller.play();
      }
    });
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

    final isFullscreenOpen = GlobalPlaybackController().isFullscreenRouteOpen;

    if (visibleFraction == 0 &&
        config.videoSourceConfiguration.pauseWhenOutOfView &&
        controller.isPlaying &&
        !isFullscreenOpen) {
      controller.pause(useGlobalController: false);
    }

    if (!controller.hasStarted &&
        config.videoSourceConfiguration.autoMuteOnStart &&
        (visibleFraction > 0.5 || isFullscreenOpen)) {
      controller.mute();
    }

    if (!controller.hasStarted &&
        config.videoSourceConfiguration.autoPlay &&
        (visibleFraction > 0.5 || isFullscreenOpen)) {
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
