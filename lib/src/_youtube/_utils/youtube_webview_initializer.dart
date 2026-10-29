import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_player_view.dart';
import 'package:omni_video_player/src/api/youtube_video_api.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Provides a fallback YouTube player using an InAppWebView-based approach.
/// Used when the native stream initialization fails or is explicitly forced.
class YouTubeWebViewInitializer implements IOmniVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration config;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final String? videoId;
  final VideoSourceConfiguration sourceConfig;
  final bool isLive;

  /// Size until oEmbed answers; defaults to [YouTubeService.startSize].
  final Size? startSize;

  const YouTubeWebViewInitializer({
    required this.config,
    required this.sourceConfig,
    required this.callbacks,
    this.videoId,
    this.globalController,
    this.isLive = false,
    this.startSize,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final resolvedVideoId =
        videoId ?? VideoId(sourceConfig.videoUrl!.toString()).toString();

    final controller = YouTubeWebViewController.fromVideoId(
      videoId: resolvedVideoId,
      duration: const Duration(seconds: 1),
      isLive: isLive,
      size: startSize ?? YouTubeService.startSize(sourceConfig.videoUrl),
      callbacks: callbacks,
      options: config,
      globalController: globalController,
      autoPlay: sourceConfig.autoPlay,
      globalKeyPlayer: config.globalKeyInitializer,
    );

    // Never awaited: loading must not wait on oEmbed (#74).
    YouTubeService.fetchVideoSize(
      resolvedVideoId,
      sourceConfig.videoUrl,
    ).then((size) => controller.size = size);

    // Register the shared player after layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.sharedPlayerNotifier.value = YouTubeWebViewPlayerView(
        key: config.globalKeyPlayer,
        controller: controller,
        customLoader: config.playerUIVisibilityOptions.showLoadingWidget
            ? config.customPlayerWidgets.loadingWidget
            : const SizedBox.shrink(),
      );
    });

    return controller;
  }
}
