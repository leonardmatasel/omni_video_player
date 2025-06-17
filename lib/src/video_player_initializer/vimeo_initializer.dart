import 'package:flutter/material.dart';
import 'package:omni_video_player/src/controllers/vimeo_playback_controller.dart';
import 'package:omni_video_player/src/api/vimeo_video_api.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/src/widgets/player/vimeo_player.dart';
import 'package:omni_video_player/omni_video_player.dart';

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
      autoPlay: options.videoSourceConfiguration.autoPlay,
      duration: vimeoVideoInfo.duration,
      size: Size(
        vimeoVideoInfo.width.toDouble(),
        vimeoVideoInfo.height.toDouble(),
      ),
      callbacks: callbacks,
    );

    controller.sharedPlayerNotifier.value = Hero(
      tag: options.globalKeyPlayer,
      child: VimeoVideoPlayer(
        key: options.globalKeyPlayer,
        videoId: videoId,
        controller: controller,
        onError: onErrorCallback,
        preferredQualities: options.videoSourceConfiguration.preferredQualities,
      ),
    );

    return controller;
  }
}
