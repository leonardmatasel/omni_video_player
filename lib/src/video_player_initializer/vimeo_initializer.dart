import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/api/vimeo_video_api.dart';
import 'package:omni_video_player/src/controllers/vimeo_playback_controller.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VimeoInitializer implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final VideoSourceConfiguration videoSourceConfiguration;

  VimeoInitializer({
    required this.options,
    this.globalController,
    required this.callbacks,
    required this.videoSourceConfiguration,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final videoId = videoSourceConfiguration.videoId!;
    final vimeoVideoInfo = await VimeoVideoApi.fetchVimeoVideoInfo(videoId);

    if (vimeoVideoInfo == null) {
      throw Exception('Failed to fetch Vimeo video info');
    }

    final controller = VimeoPlaybackController.create(
      videoId: videoId,
      globalController: globalController,
      initialPosition: videoSourceConfiguration.initialPosition,
      initialVolume: videoSourceConfiguration.initialVolume,
      size: Size(
        vimeoVideoInfo.width.toDouble(),
        vimeoVideoInfo.height.toDouble(),
      ),
      callbacks: callbacks,
      globalKeyPlayer: options.globalKeyInitializer,
      options: options,
    );

    controller.sharedPlayerNotifier.value = Hero(
      tag: options.globalKeyPlayer,
      child: WebViewWidget(
        key: options.globalKeyPlayer,
        controller: controller.webViewController,
      ),
    );
    await controller.init();

    _waitUntilReady(controller);
    callbacks.onControllerCreated?.call(controller);
    return controller;
  }

  void _waitUntilReady(VimeoPlaybackController controller) {
    controller.runOnReady(() {
      final config = videoSourceConfiguration;

      if (config.initialPosition.inSeconds > 0) {
        controller.seekTo(config.initialPosition);
      }

      if (config.autoMuteOnStart) {
        controller.mute();
      } else {
        controller.volume = config.initialVolume;
      }

      controller.playbackSpeed = config.initialPlaybackSpeed;

      if (!config.autoPlay) {
        controller.pause();
        controller.hasStarted = false;
      } else {
        controller.play();
      }
    });
  }
}
