import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_player_view.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Default 16:9 size used for the YouTube IFrame player.
///
/// The embedded YouTube player letterboxes the video internally, so this only
/// drives the aspect ratio of the surrounding container. 16:9 is correct for
/// the vast majority of YouTube videos; callers can override it via
/// [PlayerUIVisibilityOptions.customAspectRatioNormal] /
/// [PlayerUIVisibilityOptions.customAspectRatioFullScreen].
///
/// This replaces a previous network call to the third-party `noembed.com`
/// service, which had no timeout and could hang or fail intermittently on some
/// devices/networks, preventing the player from loading (see issue #74).
const Size _kDefaultYouTubeWebViewSize = Size(640, 360);

/// Provides a fallback YouTube player using an InAppWebView-based approach.
/// Used when the native stream initialization fails or is explicitly forced.
class YouTubeWebViewInitializer implements IOmniVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration config;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final String? videoId;
  final VideoSourceConfiguration sourceConfig;
  final bool isLive;

  const YouTubeWebViewInitializer({
    required this.config,
    required this.sourceConfig,
    required this.callbacks,
    this.videoId,
    this.globalController,
    this.isLive = false,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final resolvedVideoId =
        videoId ?? VideoId(sourceConfig.videoUrl!.toString()).toString();

    final controller = YouTubeWebViewController.fromVideoId(
      videoId: resolvedVideoId,
      duration: const Duration(seconds: 1),
      isLive: isLive,
      size: _kDefaultYouTubeWebViewSize,
      callbacks: callbacks,
      options: config,
      globalController: globalController,
      autoPlay: sourceConfig.autoPlay,
      globalKeyPlayer: config.globalKeyInitializer,
    );

    // Register hero widget after layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.sharedPlayerNotifier.value = Hero(
        tag: config.globalKeyPlayer,
        child: YouTubeWebViewPlayerView(
          key: config.globalKeyPlayer,
          controller: controller,
          customLoader: config.customPlayerWidgets.loadingWidget,
        ),
      );
    });

    return controller;
  }
}
