import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_player_view.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../api/youtube_video_api.dart';

/// Provides a fallback YouTube player using an InAppWebView-based approach.
/// Used when the native stream initialization fails or is explicitly forced.
class YouTubeWebViewInitializer implements IOmniVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration config;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final String? videoId;
  final Video? videoMetadata;
  final VideoSourceConfiguration sourceConfig;

  const YouTubeWebViewInitializer({
    required this.config,
    required this.sourceConfig,
    required this.callbacks,
    this.videoId,
    this.videoMetadata,
    this.globalController,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final resolvedVideoId =
        videoId ?? VideoId(sourceConfig.videoUrl!.toString()).toString();

    final videoSize = await YouTubeService.fetchYouTubeVideoSize(
      resolvedVideoId,
    );
    final videoInfo = await _resolveVideoMetadata(resolvedVideoId);

    final controller = YouTubeWebViewController.fromVideoId(
      videoId: resolvedVideoId,
      duration: const Duration(seconds: 1),
      isLive: videoInfo?.isLive ?? false,
      size: videoSize!,
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
        ),
      );
    });

    return controller;
  }

  Future<Video?> _resolveVideoMetadata(String videoId) async {
    return videoMetadata ??
        await YouTubeService.getVideoYoutubeDetails(VideoId(videoId));
  }
}
