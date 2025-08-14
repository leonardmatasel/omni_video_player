import 'package:flutter/material.dart';
import 'package:omni_video_player/src/controllers/youtube_playback_controller.dart';
import 'package:omni_video_player/src/utils/logger.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../api/youtube_video_api.dart';

class YouTubeWebViewInitializer implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final void Function()? onErrorCallback;
  String? videoId;
  final Video? ytVideo;

  YouTubeWebViewInitializer({
    required this.options,
    required this.callbacks,
    this.videoId,
    this.globalController,
    this.onErrorCallback,
    this.ytVideo,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    try {
      videoId = videoId ??
          VideoId(options.videoSourceConfiguration.videoUrl!.toString())
              .toString();
      // Usa ytVideo se disponibile, altrimenti chiamata web
      final videoInfo = ytVideo ??
          await YouTubeService.getVideoYoutubeDetails(VideoId(videoId!));
      final videoSize = await YouTubeService.fetchYouTubeVideoSize(videoId!);

      final controller = YoutubePlaybackController.fromVideoId(
        videoId: videoId!,
        duration: videoInfo.duration! - Duration(seconds: 1),
        isLive: videoInfo.isLive,
        size: videoSize!,
        callbacks: callbacks,
        globalController: globalController,
        autoPlay: options.videoSourceConfiguration.autoPlay,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.sharedPlayerNotifier.value = Hero(
          tag: options.globalKeyPlayer,
          child: WebViewWidget(
            key: options.globalKeyPlayer,
            controller: controller.webViewController,
          ),
        );
        controller.init();
      });

      await _waitUntilReady(controller);
      callbacks.onControllerCreated?.call(controller);
      return controller;
    } catch (e, st) {
      logger.e('YouTube WebView Init Error: $e', stackTrace: st);
      onErrorCallback?.call();
      return null;
    }
  }

  Future<void> _waitUntilReady(YoutubePlaybackController controller) async {
    const timeout = Duration(seconds: 30);
    const pollInterval = Duration(milliseconds: 100);
    final stopwatch = Stopwatch()..start();

    while (!controller.isReady) {
      if (stopwatch.elapsed > timeout) {
        throw Exception('WebView controller initialization timed out.');
      }
      await Future.delayed(pollInterval);
    }

    final config = options.videoSourceConfiguration;

    if (!config.autoPlay) {
      controller.pause();
      controller.hasStarted = false;
    }

    if (config.initialPosition.inSeconds > 0) {
      controller.seekTo(config.initialPosition);
    }

    controller.run('unMute');

    if (config.autoMuteOnStart) {
      controller.mute();
    } else {
      controller.volume = config.initialVolume;
    }
  }
}
