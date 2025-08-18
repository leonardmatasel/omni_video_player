import 'package:flutter/material.dart';
import 'package:omni_video_player/src/controllers/vimeo_playback_controller.dart';
import 'package:omni_video_player/src/api/vimeo_video_api.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/logger.dart';

class VimeoInitializer implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final void Function() onErrorCallback;

  VimeoInitializer({
    required this.options,
    this.globalController,
    required this.onErrorCallback,
    required this.callbacks,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    try {
      final videoId = options.videoSourceConfiguration.videoId!;
      final vimeoVideoInfo = await VimeoVideoApi.fetchVimeoVideoInfo(videoId);

      if (vimeoVideoInfo == null) {
        throw Exception('Failed to fetch Vimeo video info');
      }

      final controller = VimeoPlaybackController.create(
        videoId: videoId,
        globalController: globalController,
        initialPosition: options.videoSourceConfiguration.initialPosition,
        initialVolume: options.videoSourceConfiguration.initialVolume,
        size: Size(
          vimeoVideoInfo.width.toDouble(),
          vimeoVideoInfo.height.toDouble(),
        ),
        callbacks: callbacks,
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
      logger.e('Vimeo WebView Init Error: $e', stackTrace: st);
      onErrorCallback.call();
      return null;
    }
  }

  Future<void> _waitUntilReady(VimeoPlaybackController controller) async {
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

    controller.unMute();

    if (config.autoMuteOnStart) {
      controller.mute();
    } else {
      controller.volume = config.initialVolume;
    }
  }
}
