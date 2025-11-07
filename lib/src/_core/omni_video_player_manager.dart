import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/utils/animated_blurred_circle_background.dart';
import 'package:omni_video_player/src/_core/omni_video_player_initializer.dart';
import 'package:omni_video_player/src/_core/omni_video_player_error_view.dart';
import 'package:omni_video_player/src/_core/omni_video_player_view.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../src/_youtube/web/player_widget_interface.dart';

/// A configurable and extensible video player supporting multiple video sources.
///
/// Supports YouTube, network URLs, and local videos (other platforms planned).
/// Handles theming, initialization, controller binding, and error display.
class OmniVideoPlayerManager extends StatefulWidget {
  const OmniVideoPlayerManager({
    super.key,
    required this.configuration,
    required this.callbacks,
  });

  /// Video playback configuration and source information.
  final VideoPlayerConfiguration configuration;

  /// Callback handlers for player lifecycle and state changes.
  final VideoPlayerCallbacks callbacks;

  @override
  State<OmniVideoPlayerManager> createState() => _OmniVideoPlayerManagerState();
}

class _OmniVideoPlayerManagerState extends State<OmniVideoPlayerManager> {
  late VideoPlayerConfiguration _config = widget.configuration;
  late VideoPlayerCallbacks _callbacks = widget.callbacks;

  VideoPlayerConfiguration get config => _config;
  VideoPlayerCallbacks get callbacks => _callbacks;

  @override
  void didUpdateWidget(covariant OmniVideoPlayerManager oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldType =
        oldWidget.configuration.videoSourceConfiguration.videoSourceType;
    final newType =
        widget.configuration.videoSourceConfiguration.videoSourceType;

    if (oldType != newType) {
      setState(() {
        _config = widget.configuration;
        _callbacks = widget.callbacks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OmniVideoPlayerTheme(
      data: config.playerTheme,
      child: Stack(
        children: [_buildBackgroundOverlay(), _buildPlayerContent(context)],
      ),
    );
  }

  /// Builds the animated blurred background if configured in the theme.
  Widget _buildBackgroundOverlay() {
    final overlayColor = config.playerTheme.overlays.backgroundColor;
    final overlayAlpha = config.playerTheme.overlays.alpha;

    if (overlayColor == null || overlayAlpha == null) return SizedBox.shrink();

    final borderRadius = BorderRadius.circular(
      config.playerTheme.shapes.borderRadius,
    );

    final background = AnimatedBlurredCircleBackground(
      color: overlayColor,
      alpha: overlayAlpha,
    );

    if (config.enableBackgroundOverlayClip == true) {
      return Positioned.fill(
        child: ClipRRect(borderRadius: borderRadius, child: background),
      );
    }

    return Positioned.fill(child: background);
  }

  /// Builds the appropriate video content based on platform and source type.
  Widget _buildPlayerContent(BuildContext context) {
    final sourceType = config.videoSourceConfiguration.videoSourceType;

    if (kIsWeb && sourceType == VideoSourceType.youtube) {
      return _buildWebYoutubePlayer();
    }

    return _buildInitializedVideoPlayer();
  }

  /// Builds the YouTube player for web.
  Widget _buildWebYoutubePlayer() {
    final videoId = VideoId(
      config.videoSourceConfiguration.videoUrl!.toString(),
    ).toString();

    return Center(
      child: YoutubePlayerWidget(
        videoId: videoId,
        mute: widget.configuration.videoSourceConfiguration.autoMuteOnStart,
        autoPlay: widget.configuration.videoSourceConfiguration.autoPlay,
        start: widget
            .configuration
            .videoSourceConfiguration
            .initialPosition
            .inSeconds,
      ),
    );
  }

  /// Initializes and builds the Flutter video player with full UI and state management.
  Widget _buildInitializedVideoPlayer() {
    return OmniVideoPlayerInitializer(
      key: config.globalKeyInitializer,
      configuration: config,
      callbacks: callbacks,
      globalController: GlobalPlaybackController(),
      buildPlayer: (context, controller, thumbnail) {
        final customWidgets = config.customPlayerWidgets;
        final visibilityOptions = config.playerUIVisibilityOptions;

        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Container(
              alignment: Alignment.center,
              child: Stack(
                children: [
                  if (visibilityOptions.showLoadingWidget &&
                      !controller.isReady &&
                      !controller.hasError)
                    customWidgets.loadingWidget,
                  if (!controller.hasError)
                    OmniVideoPlayerView(
                      configuration: config.copyWith(
                        customPlayerWidgets: customWidgets.copyWith(
                          thumbnail: customWidgets.thumbnail ?? thumbnail,
                        ),
                      ),
                      callbacks: callbacks,
                      controller: controller,
                    )
                  else
                    _buildErrorPlaceholder(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds a rounded-corner error placeholder if enabled.
  Widget _buildErrorPlaceholder() {
    final borderRadius = BorderRadius.circular(
      config.playerTheme.shapes.borderRadius,
    );

    final showError = config.playerUIVisibilityOptions.showErrorPlaceholder;
    if (!showError) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: borderRadius,
      child:
          config.customPlayerWidgets.errorPlaceholder ??
          const OmniVideoPlayerErrorView(),
    );
  }
}
